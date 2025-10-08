extension String {
    var withoutANSI: String {
        let ansiPattern = "\\x1B\\[[0-9;]*[a-zA-Z]"
        return self.replacingOccurrences(
            of: ansiPattern,
            with: "",
            options: .regularExpression
        )
    }
}
