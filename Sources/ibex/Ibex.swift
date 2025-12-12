import ArgumentParser
import Foundation

@main
struct Ibex: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Ibex AI CLI - Run LLMs locally",
        subcommands: [Serve.self, Run.self, List.self, Pull.self],
        defaultSubcommand: Run.self
    )
}
