import Rainbow

let maxLength = 146

func printDotLine(label: String? = nil, value: String? = nil, terminator: String = "\n") {
    let labelLength = label?.withoutANSI.count ?? 0
    let valueLength = value?.withoutANSI.count ?? 0
    
    let dotsNeeded = maxLength - labelLength - valueLength - (label != nil ? 1 : 0) - (value != nil ? 1 : 0)
    
    let dots = String(repeating: ".", count: max(0, dotsNeeded)).lightBlack
    
    var result = "  ";
    
    if let label = label {
        result += "\(label) "
    }
    
    result += dots
    
    if let value = value {
        result += " \(value)"
    }
    
    print(result, terminator: terminator)
}

func printUpdatableDotLine(label: String? = nil, value: String? = nil, closeLine: Bool = false) {
    if closeLine {
        print("\r\u{001B}[K", terminator: "")
    }
    
    printDotLine(label: label, value: value, terminator: closeLine ? "\n" : "")
    
    if !closeLine {
        print("   ", terminator: "")
    }
}

func printTitle(_ badge: String, _ badgeType: BadgeType, _ title: String) {
    var result = " \(badge) "
    
    switch badgeType {
        case .info:
            result = result.onBlue.white
    case .error:
        result = result.onRed.black
    case .warning:
        result = result.onYellow.black
    case .success:
        result = result.onGreen.black
    }
    
    printLn()
    print("  \(result) \(title)")
    printLn()
}

func printLn()
{
    print("");
}
