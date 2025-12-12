# Build Instructions for LLMStudio Desktop App

This guide details how to build and run the SwiftUI Desktop Application (`LLMStudio`) for the Swift LLM API Server.

## Prerequisites

- **macOS**: 14.0 or later (Sonoma/Sequoia)
- **Xcode**: 16.0 or later
- **Hardware**: Mac with Apple Silicon (M1/M2/M3/M4)

## Architecture

The project is structured as a Swift Package with two main executable targets:
1. `App`: The CLI-based API Server.
2. `LLMStudio`: The SwiftUI Desktop Application.

## Method 1: Building with Command Line (Recommended)

To ensure proper compilation of Metal shaders required by MLX, allow Xcode to handle the build system via `xcodebuild`.

### 1. Build the App
Run the following command in the project root:

```bash
xcodebuild build -scheme LLMStudio -destination 'platform=macOS' -configuration Release
```

### 2. Run the App
Once built, the application bundle is located in the DerivedData directory. You can find and run it using:

```bash
# Find the app path
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/swift-llm-api-server-*/Build/Products/Release -name LLMStudio.app -type d 2>/dev/null | head -1)

# Open the app
open "$APP_PATH"
```

Or run the executable directly to see logs in the terminal:
```bash
"$APP_PATH/Contents/MacOS/LLMStudio"
```

---

## Method 2: Building with Xcode IDE

1. Open the project directory:
   ```bash
   open Package.swift
   ```
   This will open Xcode.

2. Select the Scheme:
   - In the top toolbar, click the scheme selector (next to the play/stop buttons).
   - Select **LLMStudio**.
   - Ensure the destination is set to **My Mac**.

3. Build and Run:
   - Press **Cmd + R** to build and run the application.

## Troubleshooting

### "Metal Library Not Found"
If you see errors related to Metal library loading, ensure you are building via `xcodebuild` or Xcode IDE, **NOT** via `swift build`. The standard Swift Package Manager CLI (`swift build`) currently does not automatically compile Metal shaders defined in dependencies (like MLX).

### Downloads Not Showing Up
The application stores models in a local `models/` directory within your project folder:
`./models`

Ensure the application has read/write permissions to this directory. If running from Xcode, verify the "Working Directory" in the Scheme settings:
1. CMD + < (Edit Scheme)
2. Run -> Options
3. Check "Use Custom Working Directory" and set it to your project root.

## Features

- **Model Management**: Download and delete HuggingFace models (GGUF/MLX format).
- **Local Storage**: Models are saved locally in the project folder.
- **Chat Interface**: Interact with loaded models.
- **Memory Management**: Unload models and stop generation on demand.
