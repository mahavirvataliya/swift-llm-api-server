# Installation

`ibex` is a Swift-based CLI tool optimized for Apple Silicon Macs.

## Prerequisites

- **Mac with Apple Silicon** (M1/M2/M3/M4)
- **macOS 14.0+** (Sonoma)
- **Xcode 16.0+**
- **Metal Toolchain** (Required for MLX)

## Building from Source

1. **Clone the repository**:
   ```bash
   git clone https://github.com/mahavirvataliya/swift-llm-api-server.git
   cd swift-llm-api-server
   ```

2. **Download Metal Toolchain**:
   Ensure you have the Metal toolchain installed, as MLX relies on Metal shaders.
   ```bash
   xcodebuild -downloadComponent MetalToolchain
   ```

3. **Build using Swift**:
   You can build directly with Swift Package Manager:
   ```bash
   swift build -c release
   ```
   
   *Note: If you encounter issues with Metal shaders when running via `swift run`, try building with `xcodebuild` or ensure Xcode command line tools are explicitly selected (`xcode-select -p`).*

4. **Install to Path (Optional)**:
   Copy the binary to a global location to use `ibex` from anywhere.
   ```bash
   cp .build/release/ibex /usr/local/bin/ibex
   ```

## Verification

Run the following command to verify installation:
```bash
ibex --help
```
You should see the help menu listing available subcommands (`serve`, `run`, `pull`, `list`).
