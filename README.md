# Ibex (formerly Swift LLM API Server)

A high-performance, OpenAI-compatible AI API server and CLI tool built entirely in Swift for Apple Silicon.

**Run local LLMs with ease.**

## Documentation

- 📚 [**Installation**](docs/installation.md)
- 🚀 [**Usage Guide**](docs/usage.md)
- 🏗️ [**Architecture**](docs/architecture.md)

## Features

- **Standard API**: Drop-in replacement for OpenAI API (`/v1/chat/completions`).
- **CLI Tool**: `ibex run`, `ibex pull`, `ibex serve`.
- **Embeddings**: dedicated endpoint for RAG.
- **Background Service**: Auto-starts server when needed.
- **Apple Silicon Native**: Powered by MLX.

## Quick Start

```bash
# Build
swift build -c release

# Run (Download & Chat)
.build/release/ibex run mlx-community/Llama-3.2-1B-Instruct-4bit
```

For full details, please see the [**Usage Guide**](docs/usage.md).

## License

MIT
