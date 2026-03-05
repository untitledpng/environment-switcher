import Foundation

enum FileSwitchMode: String {
    case replace
    case extend
}

enum ExtendHandler {
    case dotenv
    case magentoEnvPhp
}

func resolveFileSwitchMode(file: String, config: Config, globalConfig: GlobalConfig) -> FileSwitchMode {
    let value = config.effectiveMode(for: file, globalConfig: globalConfig).lowercased()
    return FileSwitchMode(rawValue: value) ?? .replace
}

func applySwitchForFile(
    fileManager: FileManager,
    file: String,
    environment: String,
    config: Config,
    globalConfig: GlobalConfig
) throws -> String {
    let mode = resolveFileSwitchMode(file: file, config: config, globalConfig: globalConfig)
    let environmentFilePath = getFileEnvironmentPath(file: file, environment: environment)

    guard mode == .extend else {
        try replaceFile(fileManager: fileManager, inputFilePath: environmentFilePath, outputFilePath: file)
        return "replace"
    }

    guard config.isExtendEnabled(globalConfig: globalConfig) else {
        try replaceFile(fileManager: fileManager, inputFilePath: environmentFilePath, outputFilePath: file)
        return "replace"
    }

    guard isFileWhitelistedForExtend(file: file, whitelist: config.effectiveExtendWhitelist(globalConfig: globalConfig)) else {
        try replaceFile(fileManager: fileManager, inputFilePath: environmentFilePath, outputFilePath: file)
        return "replace"
    }

    guard let handler = resolveExtendHandler(file: file) else {
        try replaceFile(fileManager: fileManager, inputFilePath: environmentFilePath, outputFilePath: file)
        return "replace"
    }

    let defaultFilePath = "\(file).default"

    switch handler {
    case .dotenv:
        try mergeDotenvFiles(fileManager: fileManager, defaultFilePath: defaultFilePath, environmentFilePath: environmentFilePath, outputFilePath: file)
        return "extend"
    case .magentoEnvPhp:
        try mergeMagentoEnvPhpFiles(fileManager: fileManager, defaultFilePath: defaultFilePath, environmentFilePath: environmentFilePath, outputFilePath: file)
        return "extend"
    }
}

private func replaceFile(fileManager: FileManager, inputFilePath: String, outputFilePath: String) throws {
    guard fileManager.fileExists(atPath: inputFilePath) else {
        throw FileError.inputFileNotFound
    }

    if fileManager.fileExists(atPath: outputFilePath) {
        try fileManager.removeItem(atPath: outputFilePath)
    }

    try fileManager.copyItem(atPath: inputFilePath, toPath: outputFilePath)
}

func resolveExtendHandler(file: String) -> ExtendHandler? {
    let fileName = (file as NSString).lastPathComponent.lowercased()

    if fileName == ".env" || fileName.hasSuffix(".env") {
        return .dotenv
    }

    if fileName == "env.php" {
        return .magentoEnvPhp
    }

    return nil
}

func isFileWhitelistedForExtend(file: String, whitelist: [String]) -> Bool {
    let normalizedFile = file.lowercased()
    let normalizedName = (file as NSString).lastPathComponent.lowercased()

    for item in whitelist {
        let value = item.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if value.isEmpty {
            continue
        }

        if normalizedFile == value || normalizedName == value {
            return true
        }

        if normalizedFile.hasSuffix(value) || normalizedName.hasSuffix(value) {
            return true
        }
    }

    return false
}

private func mergeDotenvFiles(
    fileManager: FileManager,
    defaultFilePath: String,
    environmentFilePath: String,
    outputFilePath: String
) throws {
    guard fileManager.fileExists(atPath: defaultFilePath) else {
        throw FileError.extendBaseFileNotFound
    }

    guard fileManager.fileExists(atPath: environmentFilePath) else {
        throw FileError.inputFileNotFound
    }

    let defaultContent = try String(contentsOf: URL(fileURLWithPath: defaultFilePath), encoding: .utf8)
    let environmentContent = try String(contentsOf: URL(fileURLWithPath: environmentFilePath), encoding: .utf8)

    let merged = mergeDotenv(defaultContent: defaultContent, environmentContent: environmentContent)
    try merged.write(to: URL(fileURLWithPath: outputFilePath), atomically: true, encoding: .utf8)
}

func mergeDotenv(defaultContent: String, environmentContent: String) -> String {
    let defaultLines = defaultContent.components(separatedBy: .newlines)
    let envMap = parseDotenvEntries(environmentContent)
    let defaultMap = parseDotenvEntries(defaultContent)

    var mergedMap = defaultMap
    for (key, value) in envMap {
        mergedMap[key] = value
    }

    var consumedKeys: Set<String> = []
    var outputLines: [String] = []

    for line in defaultLines {
        if let (key, _) = parseDotenvEntry(line), mergedMap[key] != nil {
            if consumedKeys.contains(key) {
                continue
            }

            outputLines.append("\(key)=\(mergedMap[key]!)")
            consumedKeys.insert(key)
            continue
        }

        outputLines.append(line)
    }

    for (key, value) in envMap where !consumedKeys.contains(key) {
        outputLines.append("\(key)=\(value)")
        consumedKeys.insert(key)
    }

    return outputLines.joined(separator: "\n")
}

private func parseDotenvEntries(_ content: String) -> [String: String] {
    var result: [String: String] = [:]
    for line in content.components(separatedBy: .newlines) {
        if let (key, value) = parseDotenvEntry(line) {
            result[key] = value
        }
    }
    return result
}

private func parseDotenvEntry(_ line: String) -> (String, String)? {
    var trimmed = line.trimmingCharacters(in: .whitespaces)

    if trimmed.isEmpty || trimmed.hasPrefix("#") {
        return nil
    }

    if trimmed.hasPrefix("export ") {
        trimmed = String(trimmed.dropFirst("export ".count)).trimmingCharacters(in: .whitespaces)
    }

    guard let separatorIndex = trimmed.firstIndex(of: "=") else {
        return nil
    }

    let key = String(trimmed[..<separatorIndex]).trimmingCharacters(in: .whitespaces)
    let valueStart = trimmed.index(after: separatorIndex)
    let value = String(trimmed[valueStart...])

    guard !key.isEmpty else {
        return nil
    }

    return (key, value)
}

private func mergeMagentoEnvPhpFiles(
    fileManager: FileManager,
    defaultFilePath: String,
    environmentFilePath: String,
    outputFilePath: String
) throws {
    guard fileManager.fileExists(atPath: defaultFilePath) else {
        throw FileError.extendBaseFileNotFound
    }

    guard fileManager.fileExists(atPath: environmentFilePath) else {
        throw FileError.inputFileNotFound
    }

    let defaultPayload = try loadPhpArray(from: defaultFilePath)
    let environmentPayload = try loadPhpArray(from: environmentFilePath)
    let merged = recursiveMergePhpValue(defaultPayload, environmentPayload)
    let rendered = renderMagentoPhpConfig(payload: merged)

    try rendered.write(to: URL(fileURLWithPath: outputFilePath), atomically: true, encoding: .utf8)
}

private func loadPhpArray(from path: String) throws -> Any {
    let script = "$payload = include $argv[1]; if (!is_array($payload)) { fwrite(STDERR, 'The included PHP file must return an array.'); exit(2);} echo json_encode($payload);"
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["php", "-r", script, path]

    let output = Pipe()
    let error = Pipe()
    process.standardOutput = output
    process.standardError = error

    try process.run()
    process.waitUntilExit()

    let outputData = output.fileHandleForReading.readDataToEndOfFile()
    let errorData = error.fileHandleForReading.readDataToEndOfFile()

    guard process.terminationStatus == 0 else {
        let message = String(data: errorData, encoding: .utf8) ?? "Unknown PHP error"
        throw FileError.phpExecutionFailed(message: message.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    guard let payload = try JSONSerialization.jsonObject(with: outputData, options: []) as? [String: Any] else {
        throw FileError.invalidPhpArrayFile
    }

    return payload
}

func recursiveMergePhpValue(_ base: Any, _ overrides: Any) -> Any {
    guard let baseDict = base as? [String: Any], let overrideDict = overrides as? [String: Any] else {
        return overrides
    }

    var merged = baseDict

    for (key, overrideValue) in overrideDict {
        if let baseValue = merged[key] {
            merged[key] = recursiveMergePhpValue(baseValue, overrideValue)
        } else {
            merged[key] = overrideValue
        }
    }

    return merged
}

func renderMagentoPhpConfig(payload: Any) -> String {
    return "<?php\nreturn \(renderPhpValue(payload, level: 0));\n"
}

private func renderPhpValue(_ value: Any, level: Int) -> String {
    if let dictionary = value as? [String: Any] {
        return renderPhpDictionary(dictionary, level: level)
    }

    if let array = value as? [Any] {
        return renderPhpArray(array, level: level)
    }

    if let boolValue = value as? Bool {
        return boolValue ? "true" : "false"
    }

    if value is NSNull {
        return "null"
    }

    if let number = value as? NSNumber {
        return number.stringValue
    }

    if let string = value as? String {
        return "'\(escapePhpString(string))'"
    }

    return "null"
}

private func renderPhpDictionary(_ value: [String: Any], level: Int) -> String {
    if value.isEmpty {
        return "[]"
    }

    let indent = String(repeating: "    ", count: level)
    let itemIndent = String(repeating: "    ", count: level + 1)
    let keys = value.keys.sorted()

    var lines: [String] = ["["]

    for key in keys {
        let renderedValue = renderPhpValue(value[key]!, level: level + 1)
        lines.append("\(itemIndent)'\(escapePhpString(key))' => \(renderedValue),")
    }

    lines.append("\(indent)]")
    return lines.joined(separator: "\n")
}

private func renderPhpArray(_ value: [Any], level: Int) -> String {
    if value.isEmpty {
        return "[]"
    }

    let indent = String(repeating: "    ", count: level)
    let itemIndent = String(repeating: "    ", count: level + 1)
    var lines: [String] = ["["]

    for item in value {
        let renderedValue = renderPhpValue(item, level: level + 1)
        lines.append("\(itemIndent)\(renderedValue),")
    }

    lines.append("\(indent)]")
    return lines.joined(separator: "\n")
}

private func escapePhpString(_ value: String) -> String {
    return value
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "'", with: "\\'")
}
