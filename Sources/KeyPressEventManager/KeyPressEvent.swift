//  Created by Axel Ancona Esselmann on 11/23/23.
//

import SwiftUI

public extension SwiftUI.EventModifiers {
    var systemImageName: String? {
        if self == .shift {
            return "shift"
        } else if self == .control {
            return "control"
        } else if self == .option {
            return "option"
        } else if self == .command {
            return "command"
        } else {
            return nil
        }
    }

    var description: String {
        if self == .shift {
            return "􀆝"
        } else if self == .control {
            return "􀆍"
        } else if self == .option {
            return "􀆕"
        } else if self == .command {
            return "􀆔"
        } else {
            return "NA"
        }
    }
}

public extension KeyEquivalent {
    var stringValue: String {
        switch self {
        case "\u{1C}": return "􀄪"
        case "\u{1D}": return "􀄫"
        case "\u{1E}": return "􀄨"
        case "\u{1F}": return "􀄩"
        case " ": return "space"
        case "\r": return "return"
        case "\t": return "tab"
        case "\u{08}": return "delete"
        case "\u{1B}": return "esc"
        default:
            let character = self.character
            return String(character)
        }
    }
}

public struct KeyPressEvent: Hashable, Identifiable, Equatable, CustomStringConvertible {
    public let id: UUID
    public let key: KeyEquivalent
    public let modifiers: SwiftUI.EventModifiers
    public var purpose: String?

    public var description: String {
        let result = "\(key.stringValue)"
        let modifiers: [String] = [
            SwiftUI.EventModifiers.shift,
            SwiftUI.EventModifiers.control,
            SwiftUI.EventModifiers.option,
            SwiftUI.EventModifiers.command
        ].filter {
            self.modifiers.contains($0)
        }.map {
            $0.description
        }
        if modifiers.isEmpty {
            return result
        } else {
            return "\(result) + \(modifiers.joined(separator: " + "))"
        }
    }


    public init(character: Character, modifiers: SwiftUI.EventModifiers, purpose: String? = nil) {
        self.id = UUID()
        self.key = KeyEquivalent(character)
        self.modifiers = modifiers
        self.purpose = purpose
    }

    public init(id: UUID, key: KeyEquivalent, modifiers: SwiftUI.EventModifiers, purpose: String?) {
        self.id = id
        self.key = key
        self.modifiers = modifiers
        self.purpose = purpose
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(modifiers.rawValue)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.key == rhs.key && lhs.modifiers.rawValue == rhs.modifiers.rawValue
    }

}
