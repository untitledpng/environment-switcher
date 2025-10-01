import Foundation

extension String {
    enum ANSIColor: String {
        case reset = "\u{001B}[0m"
        case bold = "\u{001B}[1m"
        case dim = "\u{001B}[2m"

        case black = "\u{001B}[30m"
        case red = "\u{001B}[31m"
        case green = "\u{001B}[32m"
        case yellow = "\u{001B}[33m"
        case blue = "\u{001B}[34m"
        case magenta = "\u{001B}[35m"
        case cyan = "\u{001B}[36m"
        case white = "\u{001B}[37m"

        case brightBlack = "\u{001B}[90m"
        case brightRed = "\u{001B}[91m"
        case brightGreen = "\u{001B}[92m"
        case brightYellow = "\u{001B}[93m"
        case brightBlue = "\u{001B}[94m"
        case brightMagenta = "\u{001B}[95m"
        case brightCyan = "\u{001B}[96m"
        case brightWhite = "\u{001B}[97m"
    }

    func colored(_ color: ANSIColor) -> String {
        return "\(color.rawValue)\(self)\(ANSIColor.reset.rawValue)"
    }

    var bold: String { colored(.bold) }
    var dim: String { colored(.dim) }
    var red: String { colored(.red) }
    var green: String { colored(.green) }
    var yellow: String { colored(.yellow) }
    var blue: String { colored(.blue) }
    var magenta: String { colored(.magenta) }
    var cyan: String { colored(.cyan) }
    var brightGreen: String { colored(.brightGreen) }
    var brightYellow: String { colored(.brightYellow) }
    var brightCyan: String { colored(.brightCyan) }
    var brightMagenta: String { colored(.brightMagenta) }
}
