import SwiftUI

struct ChatView: View {
    @Environment(ModelManager.self) private var modelManager
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if let loadedId = modelManager.loadedModelId {
                    Image(systemName: "cpu.fill")
                        .foregroundStyle(.green)
                    Text(loadedId.split(separator: "/").last ?? "")
                        .font(.headline)
                } else {
                    Image(systemName: "cpu")
                        .foregroundStyle(.secondary)
                    Text("No model loaded")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if !modelManager.chatMessages.isEmpty {
                    Button {
                        modelManager.chatMessages = []
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding()
            .background(.bar)
            
            Divider()
            
            // Messages
            if modelManager.loadedModelId == nil {
                ContentUnavailableView(
                    "No Model Loaded",
                    systemImage: "cpu",
                    description: Text("Go to Models tab to download and load a model")
                )
            } else if modelManager.chatMessages.isEmpty {
                ContentUnavailableView(
                    "Start a Conversation",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Type a message below to begin")
                )
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(modelManager.chatMessages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: modelManager.chatMessages.count) { _, _ in
                        if let lastMessage = modelManager.chatMessages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Input area
            HStack(spacing: 12) {
                TextField("Type a message...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .onSubmit {
                        sendMessage()
                    }
                    .disabled(modelManager.loadedModelId == nil)
                
                Button {
                    if modelManager.isGenerating {
                        modelManager.stopGeneration()
                    } else {
                        sendMessage()
                    }
                } label: {
                    if modelManager.isGenerating {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                }
                .buttonStyle(.borderless)
                .disabled((inputText.isEmpty && !modelManager.isGenerating) || modelManager.loadedModelId == nil)
            }
            .padding()
            .background(.bar)
        }
        .frame(minWidth: 400)
        .alert("Error", isPresented: .init(
            get: { modelManager.errorMessage != nil },
            set: { if !$0 { modelManager.errorMessage = nil } }
        )) {
            Button("OK") { modelManager.errorMessage = nil }
        } message: {
            if let error = modelManager.errorMessage {
                Text(error)
            }
        }
    }
    
    private func sendMessage() {
        let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        inputText = ""
        Task {
            await modelManager.sendMessage(message)
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var isUser: Bool { message.role == "user" }
    
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isUser ? Color.accentColor : Color(.controlBackgroundColor))
                    .foregroundStyle(isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            if !isUser { Spacer(minLength: 60) }
        }
    }
}

#Preview {
    ChatView()
        .environment(ModelManager())
        .frame(width: 600, height: 500)
}
