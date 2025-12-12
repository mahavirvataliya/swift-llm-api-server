import ArgumentParser
import Foundation

struct Run: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Run a model and chat with it (Client mode)"
    )

    @Argument(help: "The model to run (e.g. mlx-community/Llama-3.2-1B-Instruct-4bit)")
    var model: String = "mlx-community/Llama-3.2-1B-Instruct-4bit"

    @Option(name: .shortAndLong, help: "Hostname of the server")
    var hostname: String = "127.0.0.1"

    @Option(name: .shortAndLong, help: "Port of the server")
    var port: Int = 8080

    func run() async throws {
        print("Starting client for model: \(model)...")
        
        // 1. Check if server is reachable
        let serverURL = URL(string: "http://\(hostname):\(port)")!
        let healthURL = serverURL.appendingPathComponent("health")
        
        var isServerRunning = false
        do {
            let (_, response) = try await URLSession.shared.data(from: healthURL)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                isServerRunning = true
            }
        } catch {
            isServerRunning = false
        }
        
        if !isServerRunning {
            print("⚠️ Server not running. Starting ibex server in background...")
            
            guard let executable = Bundle.main.executableURL else {
                print("❌ Could not find executable path.")
                return
            }
            
            let process = Process()
            process.executableURL = executable
            process.arguments = ["serve", "--model", model, "--port", "\(port)", "--hostname", hostname]
            
            let logFile = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("server.log")
            if !FileManager.default.fileExists(atPath: logFile.path) {
                FileManager.default.createFile(atPath: logFile.path, contents: nil)
            }
            
            let fileHandle = try FileHandle(forWritingTo: logFile)
            fileHandle.seekToEndOfFile()
            process.standardOutput = fileHandle
            process.standardError = fileHandle
            
            try process.run()
            
            print("⏳ Waiting for server to initialize (logs at \(logFile.lastPathComponent))...")
            
            // Wait for health
            var attempts = 0
            while attempts < 300 { // 5 minutes timeout (model loading can be slow)
                try await Task.sleep(nanoseconds: 1_000_000_000)
                do {
                    let (_, response) = try await URLSession.shared.data(from: healthURL)
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        isServerRunning = true
                        print("✅ Server started!")
                        break
                    }
                } catch {
                    // ignore and retry
                }
                attempts += 1
                if attempts % 5 == 0 { print(".", terminator: "") }
                fflush(stdout)
            }
            print("")
            
            if !isServerRunning {
                print("❌ Server failed to start in time. Check ./server.log for details.")
                return
            }
        }
        
        print("✅ Connected to ibex server.")
        print("Type 'exit' or 'quit' to end the chat.")
        print("--------------------------------------------------")
        
        // 2. Chat Loop
        var history: [[String: String]] = [
            ["role": "system", "content": "You are a helpful AI assistant."]
        ]
        
        while true {
            print("\n>>> ", terminator: "")
            guard let input = readLine(), !input.isEmpty else { continue }
            
            if input.lowercased() == "exit" || input.lowercased() == "quit" {
                break
            }
            
            // Add user message
            history.append(["role": "user", "content": input])
            
            // call API
            do {
                try await chat(messages: history, serverURL: serverURL)
            } catch {
                print("\n❌ Error: \(error.localizedDescription)")
            }
        }
    }
    
    func chat(messages: [[String: String]], serverURL: URL) async throws {
        let chatURL = serverURL.appendingPathComponent("v1/chat/completions")
        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "stream": true // We will try to handle streaming
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (params, _) = try await URLSession.shared.bytes(for: request)
        
        for try await line in params.lines {
            if line.hasPrefix("data: ") {
                let data = line.dropFirst(6)
                if data == "[DONE]" { break }
                
                guard let jsonData = data.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let delta = choices.first?["delta"] as? [String: Any],
                      let content = delta["content"] as? String else {
                    continue
                }
                
                print(content, terminator: "")
                fflush(stdout)
                
                // Append to last assistant message in history if we were tracking it reliably, 
                // but for this simple client we just print. 
                // In a real app we'd update history.
            }
        }
        print("") // Newline at end
        
        // Note: We are not updating `history` with the assistant response here for simplicity in this MVP 
        // because streaming makes it harder to reconstruct the full message without buffering.
        // For a better experience, we should buffer.
    }
}
