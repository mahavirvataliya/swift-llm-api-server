import ArgumentParser
import Hub
import Foundation

struct Pull: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Pull a model or embedding model from HuggingFace to local cache"
    )

    @Argument(help: "The HuggingFace model ID (e.g. mlx-community/Llama-3.2-1B-Instruct-4bit)")
    var model: String
    
    @Flag(help: "Verbose output")
    var verbose: Bool = false

    func run() async throws {
        print("📥 Pulling \(model)...")
        
        // Attempt to use HubApi to download snapshot without loading weights into RAM
        let hub = HubApi()
        let repo = Hub.Repo(id: model)
        
        do {
            let localPath = try await hub.snapshot(from: repo, progressHandler: { progress in
                let percentage = Int(progress.fractionCompleted * 100)
                let completed = ByteCountFormatter.string(fromByteCount: progress.completedUnitCount, countStyle: .file)
                let total = ByteCountFormatter.string(fromByteCount: progress.totalUnitCount, countStyle: .file)
                
                print("Downloading: \(percentage)% (\(completed) / \(total))", terminator: "\r")
                fflush(stdout)
            })
            print("\n✅ Successfully pulled to: \(localPath.path)")
            print("--------------------------------------------------")
            print("To run this model (LLM):")
            print("  ibex run \(model)")
            print("To serve this model (LLM):")
            print("  ibex serve --model \(model)")
            print("To serve as embedding model:")
            print("  ibex serve --embedding-model \(model)")
            print("--------------------------------------------------")
            
        } catch {
            print("\n❌ Failed to pull model: \(error.localizedDescription)")
            print("Make sure the model ID is correct and you have internet connection.")
            if verbose {
                print("Error details: \(error)")
            }
        }
    }
}
