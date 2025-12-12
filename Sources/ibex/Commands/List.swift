import ArgumentParser

struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List available models"
    )

    func run() async throws {
        print("Available models:")
        // In a real implementation we would scan the ~/.cache/huggingface/hub directory
        print("  mlx-community/Llama-3.2-1B-Instruct-4bit (Default)")
        print("  (You can use any HuggingFace model ID with 'ibex run <model_id>')")
    }
}
