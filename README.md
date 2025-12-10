# Swift LLM API Server

A lightweight, OpenAI-compatible inference server built entirely in Swift, powered by [MLX](https://github.com/ml-explore/mlx-swift) for Apple Silicon Macs.

Run local LLMs with an API that works seamlessly with any OpenAI client library or tool.

## Features

- 🚀 **OpenAI API Compatible** - Drop-in replacement for `/v1/chat/completions`
- ⚡ **Streaming Support** - Real-time Server-Sent Events (SSE) responses
- 🍎 **Apple Silicon Optimized** - Leverages MLX for maximum performance on M1/M2/M3/M4
- 📦 **HuggingFace Integration** - Auto-downloads models from `mlx-community`
- 🔧 **Headless/Daemon Mode** - Runs in background like Ollama

## Prerequisites

- **Hardware**: Mac with Apple Silicon (M1/M2/M3/M4)
- **macOS**: 14.0+
- **Xcode**: 16.0+ (with Metal Toolchain)

## Installation

```bash
# Clone the repository
git clone https://github.com/mahavirvataliya/swift-llm-api-server.git
cd swift-llm-api-server

# Download Metal Toolchain (one-time)
xcodebuild -downloadComponent MetalToolchain

# Build with xcodebuild (required for Metal shader compilation)
xcodebuild build -scheme swift-llm-api-server -destination 'platform=macOS' -configuration Release
```

> ⚠️ **Important**: You must use `xcodebuild`, not `swift build`. The Swift Package Manager CLI doesn't compile Metal shaders, which MLX requires.

## Running the Server

```bash
# Find the built executable
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/swift-llm-api-server-*/Build/Products/Release -name App -type f 2>/dev/null | head -1)

# Run with default model (Llama-3.2-1B-Instruct-4bit)
$APP_PATH

# Or with custom options
$APP_PATH --model mlx-community/Mistral-7B-Instruct-v0.3-4bit --port 8080 --hostname 0.0.0.0
```

The first run will download the model from HuggingFace (~500MB-2GB depending on model).

## Usage

### Health Check

```bash
curl http://localhost:8080/health
# OK
```

### Chat Completion

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "local-model",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Hello!"}
    ]
  }'
```

### Streaming

```bash
curl -N http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "local-model",
    "messages": [{"role": "user", "content": "Count to 5"}],
    "stream": true
  }'
```

### Use with Python OpenAI SDK

```python
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8080/v1", api_key="not-needed")

response = client.chat.completions.create(
    model="local-model",
    messages=[{"role": "user", "content": "Hello!"}]
)
print(response.choices[0].message.content)
```

## Configuration

| Flag | Default | Description |
|------|---------|-------------|
| `--hostname`, `-h` | `127.0.0.1` | Server bind address |
| `--port`, `-p` | `8080` | Server port |
| `--model`, `-m` | `mlx-community/Llama-3.2-1B-Instruct-4bit` | HuggingFace model ID |

## Supported Models

Any MLX-converted model from [mlx-community](https://huggingface.co/mlx-community) works:

- `mlx-community/Llama-3.2-1B-Instruct-4bit`
- `mlx-community/Llama-3.2-3B-Instruct-4bit`
- `mlx-community/Mistral-7B-Instruct-v0.3-4bit`
- `mlx-community/Qwen2.5-7B-Instruct-4bit`
- And many more...

## Project Structure

```
swift-llm-api-server/
├── Package.swift
└── Sources/App/
    ├── App.swift                 # Entry point, CLI args, server bootstrap
    ├── Controllers/
    │   └── OpenAIController.swift # API routes & SSE streaming
    ├── Inference/
    │   └── ModelActor.swift      # Thread-safe MLX model management
    └── APIModels/
        ├── OpenAIRequests.swift  # Request DTOs
        └── OpenAIResponses.swift # Response DTOs
```

## License

MIT
