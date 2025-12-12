import SwiftUI

struct ModelListView: View {
    @Environment(ModelManager.self) private var modelManager
    @Binding var selectedTab: Int
    @State private var showDeleteConfirmation = false
    @State private var modelToDelete: LocalModel?
    
    var body: some View {
        NavigationSplitView {
            List {
                // Downloaded Models Section
                Section("Downloaded Models") {
                    if modelManager.downloadedModels.isEmpty {
                        Text("No models downloaded yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(modelManager.downloadedModels) { model in
                            DownloadedModelRow(model: model)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        modelToDelete = model
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                
                // Recommended Models Section
                Section("Available Models") {
                    ForEach(RecommendedModel.all) { model in
                        RecommendedModelRow(model: model)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Models")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task {
                             await modelManager.refreshLocalModels()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        } detail: {
            if let loadedId = modelManager.loadedModelId {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                    
                    VStack(spacing: 8) {
                        Text("Model Loaded")
                            .font(.title2)
                            .bold()
                        Text(loadedId)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    HStack(spacing: 16) {
                        Button("Go to Chat") {
                            selectedTab = 1
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Button("Unload Model") {
                            modelManager.unloadModel()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(.red)
                    }
                    .padding(.top)
                }
                .padding()
            } else {
                ContentUnavailableView(
                    "No Model Selected",
                    systemImage: "cpu",
                    description: Text("Download and load a model to get started")
                )
            }
        }
        .alert("Delete Model?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let model = modelToDelete {
                    modelManager.deleteModel(model)
                }
            }
        } message: {
            if let model = modelToDelete {
                Text("This will remove \(model.name) from your computer.")
            }
        }
    }
}

struct DownloadedModelRow: View {
    @Environment(ModelManager.self) private var modelManager
    let model: LocalModel
    
    var isLoaded: Bool {
        modelManager.loadedModelId == model.modelId
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.headline)
                HStack {
                    Text(model.sizeFormatted)
                    if let date = model.downloadDate {
                        Text("•")
                        Text(date, style: .date)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isLoaded {
                Label("Loaded", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            } else {
                Button {
                    Task {
                        await modelManager.loadModel(id: model.modelId)
                    }
                } label: {
                    if modelManager.isModelLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Text("Load")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(modelManager.isModelLoading)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RecommendedModelRow: View {
    @Environment(ModelManager.self) private var modelManager
    let model: RecommendedModel
    
    var isDownloaded: Bool {
        modelManager.downloadedModels.contains { $0.modelId == model.modelId }
    }
    
    var isDownloading: Bool {
        modelManager.downloadingModels.contains(model.modelId)
    }
    
    var downloadProgress: Double {
        modelManager.downloadProgress[model.modelId] ?? 0
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.headline)
                Text(model.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.1f GB", model.sizeGB))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            if isDownloaded {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if isDownloading {
                VStack {
                    ProgressView(value: downloadProgress)
                        .frame(width: 80)
                    Text("\(Int(downloadProgress * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    Task {
                        await modelManager.downloadModel(id: model.modelId)
                    }
                } label: {
                    Label("Download", systemImage: "arrow.down.circle")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ModelListView(selectedTab: .constant(0))
        .environment(ModelManager())
}
