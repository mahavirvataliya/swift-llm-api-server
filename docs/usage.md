# Usage Guide

`ibex` is designed to be a simple, all-in-one CLI for running local Large Language Models (LLMs) and Embedding models.

## CLI Overview

- **`ibex run`**: Interactive chat mode (auto-starts server).
- **`ibex server`**: Starts the HTTP Inference Server.
- **`ibex pull`**: Downloads models from HuggingFace.
- **`ibex list`**: Lists available models.

---

## 1. Running Models Interactively (`ibex run`)

The easiest way to chat with a model.

```bash
# Run with the default model (Llama-3.2-1B)
ibex run

# Run with a specific model
ibex run mlx-community/Llama-3.2-3B-Instruct-4bit
```

**Features:**
- ✨ **Auto-Start**: If the server isn't running, `ibex` automatically starts a background process.
- 💬 **Streaming**: Responses stream in real-time.
- 💾 **History**: Maintains chat history for the session.

---

## 2. Serving Models Requests (`ibex serve`)

Start a dedicated OpenAI-compatible API server. This is useful for building apps or using third-party clients (like Chatbox, web UIs).

### Usage

```bash
ibex serve --model <model_id> --embedding-model <embed_id>
```

### Examples

**Serve Chat Model Only:**
```bash
ibex serve --model mlx-community/Llama-3.2-1B-Instruct-4bit
```

**Serve Embedding Model Only:**
```bash
ibex serve --embedding-model nomic-ai/nomic-embed-text-v1.5
```

**Serve Both:**
```bash
ibex serve \
  --model mlx-community/Llama-3.2-1B-Instruct-4bit \
  --embedding-model nomic-ai/nomic-embed-text-v1.5
```

**Custom Host/Port:**
```bash
ibex serve --port 9090 --hostname 0.0.0.0
```

---

## 3. Managing Models (`ibex pull`)

Pre-download models to your local cache so they can be used offline.

```bash
# Pull an LLM
ibex pull mlx-community/Mistral-7B-Instruct-v0.3-4bit

# Pull an Embedding model
ibex pull nomic-ai/nomic-embed-text-v1.5
```

Models are stored in `~/.cache/huggingface/hub` (standard HuggingFace location) so they are shared with other tools.

---

## 4. API Endpoints

Once the server is running, you can interact with it via `curl` or any OpenAI SDK.

### Chat Completions (`POST /v1/chat/completions`)

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "local-model",
    "messages": [
      {"role": "user", "content": "Hello!"}
    ],
    "stream": true
  }'
```

### Embeddings (`POST /v1/embeddings`)

```bash
curl http://localhost:8080/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nomic-ai/nomic-embed-text-v1.5",
    "input": "The food was delicious"
  }'
```

### Health Check (`GET /health`)

```bash
curl http://localhost:8080/health
```

---

## 5. Tray App (`ibex-tray`)

The Tray App provides a macOS menu bar interface for running the Ibex server in the background.

### Running the Tray App

```bash
# Build the tray app
swift build --product ibex-tray

# Run the tray app
.build/debug/ibex-tray
```

### Features

- **🖥️ Menu Bar Icon**: Shows server status (running/stopped)
- **⚡ Lazy Loading**: Models load on first request, not at startup
- **⚙️ Settings UI**: Configure port and model storage directory
- **🔄 Auto-Start**: Server starts automatically when app launches

### Settings

Open Settings from the menu bar to configure:
- **Port**: Server port (default: 8080)
- **Model Directory**: Where models are stored (default: `~/.ibex/models`)

### How Lazy Loading Works

Unlike `ibex serve`, the tray app starts the server without loading any models. When you send your first API request, the model specified in the `model` field of your request will be downloaded (if needed) and loaded automatically.

```bash
# This will trigger model download and loading
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mlx-community/Llama-3.2-1B-Instruct-4bit",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

---

## 6. Configuration

### Model Storage Directory

By default, models are stored in:
- **Tray App**: `~/.ibex/models`
- **CLI (`ibex pull`)**: `~/.cache/huggingface/hub` (standard HuggingFace location)

You can change the tray app's model directory in the Settings window.

