import InputMethodKit
import ArgumentParser

enum ImSwitchError: Error {
    case failedToChangeInputSource
    case specifiedInputSourceIsNotAvailable
    case unknown
}

extension ImSwitchError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .failedToChangeInputSource:
            "Failed to change input source."
        case .specifiedInputSourceIsNotAvailable:
            "Specified Input Source ID is not available."
        case .unknown:
            "Unknown error happend."
        }
    }
}

extension TISInputSource {
    enum Category {
        static var keyboardInputSource: String {
            return kTISCategoryKeyboardInputSource as String
        }
    }

    func getProperty(_ key: CFString) -> AnyObject? {
        guard let cfType = TISGetInputSourceProperty(self, key) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(cfType).takeUnretainedValue()
    }

    var id: String {
        return getProperty(kTISPropertyInputSourceID) as! String
    }

    var localizedName: String {
        return getProperty(kTISPropertyLocalizedName) as! String
    }

    var isSelectCapable: Bool {
        return getProperty(kTISPropertyInputSourceIsSelectCapable) as! Bool
    }

    var category: String {
        return getProperty(kTISPropertyInputSourceCategory) as! String
    }

    var isSelected: Bool {
        return getProperty(kTISPropertyInputSourceIsSelected) as! Bool
    }

    var sourceLanguages: [String] {
        return getProperty(kTISPropertyInputSourceLanguages) as! [String]
    }
}

class InputSource {
    fileprivate static var inputSources: [TISInputSource] {
        let inputSourceNSArray = TISCreateInputSourceList(nil, false)
            .takeRetainedValue() as NSArray
        return inputSourceNSArray as! [TISInputSource]
    }

    fileprivate static var currentInputSource: TISInputSource {
        return TISCopyCurrentKeyboardInputSource()
            .takeRetainedValue()
    }

    fileprivate static var selectCapableInputSources: [TISInputSource] {
        return inputSources
            .filter {
                $0.isSelectCapable && $0.category == TISInputSource.Category.keyboardInputSource
            }
    }

    private static func select(_ inputSource: TISInputSource) throws {
        if TISSelectInputSource(inputSource) != noErr {
            throw ImSwitchError.failedToChangeInputSource
        }
    }

    fileprivate static func select(_ id: String) throws {
        guard let inputSource = selectCapableInputSources.filter({ $0.id == id }).first else {
            throw ImSwitchError.specifiedInputSourceIsNotAvailable
        }
        try select(inputSource)
    }

    fileprivate static func selectNextInputSource() throws -> (before: TISInputSource, after: TISInputSource) {
        let before = currentInputSource
        guard let currentIndex = selectCapableInputSources.firstIndex(of: currentInputSource) else {
            throw ImSwitchError.unknown
        }
        let nextIndex = (currentIndex + 1) % selectCapableInputSources.count
        let nextInputSource = selectCapableInputSources[nextIndex]
        try select(nextInputSource)
        return (before, nextInputSource)
    }
}

extension ImSwitch {
    struct List: ParsableCommand {
        static let configuration =
            CommandConfiguration(abstract: "List of available input sources.")

        @Flag(name: .shortAndLong)
        var verbose = false

        func run() {
            if verbose {
                for source in InputSource.selectCapableInputSources {
                    print("\(source.isSelected ? "*" : " ") \(source.id) (\(source.localizedName))")
                }
            } else {
                for source in InputSource.selectCapableInputSources {
                    print("\(source.id)")
                }
            }
        }
    }

    struct Select: ParsableCommand {
        static let configuration =
            CommandConfiguration(abstract: "Switch to the specified input source.")

        @Argument(help: "Input Source ID (e.g. com.apple.keylayout.ABC).")
        var id: String

        func run() throws {
            try InputSource.select(id)
        }
    }

    struct Next: ParsableCommand {
        static let configuration =
            CommandConfiguration(abstract: "Select the next input source.")

        @Flag(name: .shortAndLong)
        var verbose = false

        func run() throws {
            let (before, after) = try InputSource.selectNextInputSource()
            if verbose {
                print("\(before.localizedName) -> \(after.localizedName)")
            }
        }
    }
}

@main
struct ImSwitch: ParsableCommand {
    static let configuration = CommandConfiguration(
        subcommands: [List.self, Select.self, Next.self]
    )
}
