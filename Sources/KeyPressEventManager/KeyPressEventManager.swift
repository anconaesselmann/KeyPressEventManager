//  Created by Axel Ancona Esselmann on 11/23/23.
//

import SwiftUI
import Combine

@MainActor
public class KeyPressEventManager {

    public enum Error: Swift.Error {
        case blocked(String)
    }

    public static let shared = KeyPressEventManager()

    public let events = PassthroughSubject<KeyPressEvent, Never>()
    public let listening = CurrentValueSubject<Bool, Never>(false)

    private var registered = Set<KeyPressEvent>()

    private var blocked = Set<KeyPressEvent>()

    private var supressed = Set<KeyPressEvent>()

    public func register(_ event: KeyPressEvent) throws {
        guard !blocked.contains(event) else {
            throw Error.blocked(event.description)
        }
        registered.insert(event)
    }

    public func blockForApplicationUse(_ keyEvents: KeyPressEvent...) {
        self.blockForApplicationUse(keyEvents)
    }

    public func blockForApplicationUse(_ keyEvents: [KeyPressEvent]) {
        self.blocked = Set(keyEvents)
    }

    public func addBlockForApplicationUse(_ keyEvents: KeyPressEvent...) {
        self.addBlockForApplicationUse(keyEvents)
    }

    public func addBlockForApplicationUse(_ keyEvents: [KeyPressEvent]) {
        self.blocked = self.blocked.union(Set(keyEvents))
    }

    public func supressOsEvents(_ keyEvents: KeyPressEvent...) {
        self.supressed = Set(keyEvents)
    }

    public func isBlocked(_ keyEvent: KeyPressEvent) -> Bool {
        self.blocked.contains(keyEvent)
    }

#if os(macOS)
    private init() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.onKeyPressEvent(event)
        }
    }

    private func onKeyPressEvent(_ event: NSEvent) -> NSEvent? {

        guard let keyPressEvent = KeyPressEvent(event: event) else {
            return event
        }
        events.send(keyPressEvent)
        guard !listening.value else {
            listening.send(false)
            return nil
        }
        guard !registered.contains(keyPressEvent) else {
            return nil
        }
        guard !supressed.contains(keyPressEvent) else {
            return nil
        }
        guard !blocked.contains(keyPressEvent) else {
            return nil
        }
        return event
    }
#endif
}

#if os(macOS)
import Carbon

public extension KeyPressEvent {
    init?(event: NSEvent) {
        guard let keyName = keyName(virtualKeyCode: event.keyCode) else {
            return nil
        }
        let individualModifiers =
        [
            NSEvent.ModifierFlags.shift,
            NSEvent.ModifierFlags.control,
            NSEvent.ModifierFlags.option,
            NSEvent.ModifierFlags.command
        ].filter {
            event.modifierFlags.contains($0)
        }.compactMap {
            $0.swiftUiEventModifier
        }
        let modifiers = individualModifiers.reduce(into: SwiftUI.EventModifiers()) {
            $0.insert($1)
        }
        self.init(character: Character(keyName), modifiers: modifiers)
    }
}

public extension NSEvent.ModifierFlags {

    var swiftUiEventModifier: SwiftUI.EventModifiers? {
        if self == .shift {
            return .shift
        } else if self == .control {
            return .control
        } else if self == .option {
            return .option
        } else if self == .command {
            return .command
        } else {
            return nil
        }
    }
}

func keyName(virtualKeyCode: UInt16) -> String? {
    let maxNameLength = 4
    var nameBuffer = [UniChar](repeating: 0, count : maxNameLength)
    var nameLength = 0

    let modifierKeys = UInt32(alphaLock >> 8) & 0xFF // Caps Lock
    var deadKeys: UInt32 = 0
    let keyboardType = UInt32(LMGetKbdType())

    let source = TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue()
    guard let ptr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
        NSLog("Could not get keyboard layout data")
        return nil
    }
    let layoutData = Unmanaged<CFData>.fromOpaque(ptr).takeUnretainedValue() as Data
    let osStatus = layoutData.withUnsafeBytes {
        UCKeyTranslate($0.bindMemory(to: UCKeyboardLayout.self).baseAddress, virtualKeyCode, UInt16(kUCKeyActionDown),
                       modifierKeys, keyboardType, UInt32(kUCKeyTranslateNoDeadKeysMask),
                       &deadKeys, maxNameLength, &nameLength, &nameBuffer)
    }
    guard osStatus == noErr else {
        NSLog("Code: 0x%04X  Status: %+i", virtualKeyCode, osStatus);
        return nil
    }

    return  String(utf16CodeUnits: nameBuffer, count: nameLength)
}

// https://support.apple.com/en-us/HT201236
public struct OSKeyboardShortcuts {
    public static let all: [KeyPressEvent] = [
        KeyPressEvent(character: "X", modifiers: [.command], purpose: "Cut the selected item and copy it to the Clipboard."),
        KeyPressEvent(character: "C", modifiers: [.command], purpose: "Copy the selected item to the Clipboard. This also works for files in the Finder."),
        KeyPressEvent(character: "V", modifiers: [.command], purpose: "Paste the contents of the Clipboard into the current document or app. This also works for files in the Finder."),
//            KeyPressEvent(character: "Z", modifiers: [.command], purpose: "Undo the previous command. You can then press Shift-Command-Z to Redo, reversing the undo command. In some apps, you can undo and redo multiple commands."),
        KeyPressEvent(character: "A", modifiers: [.command], purpose: "Select All items."),
        KeyPressEvent(character: "F", modifiers: [.command], purpose: "Find items in a document or open a Find window."),
        KeyPressEvent(character: "G", modifiers: [.command], purpose: "Find Again: Find the next occurrence of the item previously found."),
        KeyPressEvent(character: "G", modifiers: [.shift, .command], purpose: "Find Again: Find the previous occurrence."),
        KeyPressEvent(character: "H", modifiers: [.command], purpose: "Hide the windows of the front app. To view the front app but hide all other apps, press Option-Command-H."),
        KeyPressEvent(character: "M", modifiers: [.command], purpose: "Minimize the front window to the Dock. To minimize all windows of the front app, press Option-Command-M."),
        KeyPressEvent(character: "O", modifiers: [.command], purpose: "Open the selected item, or open a dialog to select a file to open."),
        KeyPressEvent(character: "P", modifiers: [.command], purpose: "Print the current document."),
        KeyPressEvent(character: "S", modifiers: [.command], purpose: "Save the current document."),
        KeyPressEvent(character: "T", modifiers: [.command], purpose: "Open a new tab."),
        KeyPressEvent(character: "W", modifiers: [.command], purpose: "Close the front window. To close all windows of the app, press Option-Command-W."),
        KeyPressEvent(character: "\u{1B}", modifiers: [.option, .command], purpose: "Force quit an app."),
        KeyPressEvent(character: " ", modifiers: [.command], purpose: "Show or hide the Spotlight search field."),
        KeyPressEvent(character: " ", modifiers: [.control, .command], purpose: "Show the Character Viewer, from which you can choose emoji and other symbols."),
        KeyPressEvent(character: "F", modifiers: [.control, .command], purpose: "Use the app in full screen, if supported by the app."),
        KeyPressEvent(character: " ", modifiers: [], purpose: "Use Quick Look to preview the selected item."),
        KeyPressEvent(character: "\t", modifiers: [.command], purpose: "Switch to the next most recently used app among your open apps."),
        KeyPressEvent(character: "`", modifiers: [.command], purpose: "Switch between the windows of the app you're using."),
        KeyPressEvent(character: "3", modifiers: [.command, .shift], purpose: "Screenshots"),
        KeyPressEvent(character: "4", modifiers: [.command, .shift], purpose: "Screenshots"),
        KeyPressEvent(character: "5", modifiers: [.command, .shift], purpose: "Take a screenshot or make a screen recording"),
        KeyPressEvent(character: "N", modifiers: [.command, .shift], purpose: "Create a new folder in the Finder."),
        KeyPressEvent(character: ",", modifiers: [.command], purpose: "Open preferences for the front app."),
    ]
}

#endif
