# Architecture

`ibex` is built on a modern Swift stack designed for performance and concurrency.

## Core Components

### 1. **Hummingbird (Web Server)**
- High-performance, asynchronous HTTP server.
- Handles routing (`Sources/ibex/Controllers/`).
- Manages SSE (Server-Sent Events) for streaming responses.

### 2. **MLX (Inference Engine)**
- Uses `mlx-swift`, an array framework for machine learning on Apple Silicon.
- `MLXLLM`: Optimized LLM implementations (Llama, Mistral, Qwen, etc.).
- `MLXEmbedders`: Optimized embedding generation (BERT, Nomic, etc.).

### 3. **Actors (Concurrency)**
To ensure thread safety while allowing concurrent HTTP requests, model inference is isolated in Swift Actors.

- **`ModelActor`** (`Sources/ibex/Inference/ModelActor.swift`):
  - Manages the LLM state (weights, KV cache).
  - Serializes generation requests (token-by-token generation).
  
- **`EmbeddingActor`** (`Sources/ibex/Inference/EmbeddingActor.swift`):
  - Manages the embedding model.
  - Handles batch processing of text inputs.

### 4. **CLI (ArgumentParser)**
- Built with `swift-argument-parser`.
- Structured as subcommands (`Serve`, `Run`, `Pull`) for extensibility.
- **Client Logic**: The `run` command acts as a lightweight HTTP client that communicates with the `serve` process (even effectively "self-hosting" via background process).

## Data Flow

1. **Request**: User sends HTTP POST to `/v1/chat/completions`.
2. **Controller**: `OpenAIController` receives request, validates DTO.
3. **Actor**: Controller calls `await modelActor.generate(...)`.
4. **MLX**: Actor invokes `MLXLLM` to generate tokens on GPU/ANE.
5. **Stream**: Tokens are yielded back to Controller -> AsyncStream -> HTTP SSE response.
