import InputMethodKit
import ArgumentParser

enum ImSwitchError: Error {
}

extension ImSwitchError: LocalizedError {
}

extension ImSwitch {
    struct List: ParsableCommand {
        @Flag(name: .shortAndLong)
        var verbose = false

        func run() {
            if verbose {
                print("list -v")
            } else {
                print("list")
            }
        }
    }

    struct Select: ParsableCommand {
        @Argument(help: "Input Source ID (e.g. com.apple.keylayout.ABC).")
        var id: String

        func run() throws {
            print("select \(id)")
        }
    }

    struct Next: ParsableCommand {
        func run() throws {
            print("next")
        }
    }
}

@main
struct ImSwitch: ParsableCommand {
    static let configuration = CommandConfiguration(
        subcommands: [List.self, Select.self, Next.self]
    )
}
