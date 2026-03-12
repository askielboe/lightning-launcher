import SwiftUI
import ServiceManagement

/// Settings window UI for Lightning.
struct SettingsView: View {
    @State private var maxResults: Double
    @State private var launchAtLogin: Bool
    @State private var additionalPaths: [String]
    @State private var showPathPicker = false

    init() {
        let prefs = UserPreferences.shared
        _maxResults = State(initialValue: Double(prefs.maxResults))
        _launchAtLogin = State(initialValue: prefs.launchAtLogin)
        _additionalPaths = State(initialValue: prefs.additionalSearchPaths)
    }

    var body: some View {
        Form {
            Section("General") {
                HotKeyRecorderView()

                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        UserPreferences.shared.launchAtLogin = newValue
                        updateLoginItem(enabled: newValue)
                    }

                HStack {
                    Text("Max results")
                    Slider(value: $maxResults, in: 4...12, step: 1)
                    Text("\(Int(maxResults))")
                        .monospacedDigit()
                        .frame(width: 20)
                }
                .onChange(of: maxResults) { newValue in
                    UserPreferences.shared.maxResults = Int(newValue)
                }
            }

            Section("Search Paths") {
                Text("Additional directories to search for apps:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(additionalPaths, id: \.self) { path in
                    HStack {
                        Text(path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button(role: .destructive) {
                            additionalPaths.removeAll { $0 == path }
                            UserPreferences.shared.additionalSearchPaths = additionalPaths
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                Button("Add Path...") {
                    showPathPicker = true
                }
                .fileImporter(
                    isPresented: $showPathPicker,
                    allowedContentTypes: [.folder]
                ) { result in
                    if case .success(let url) = result {
                        let path = url.path
                        if !additionalPaths.contains(path) {
                            additionalPaths.append(path)
                            UserPreferences.shared.additionalSearchPaths = additionalPaths
                        }
                    }
                }
            }

            Section("About") {
                HStack {
                    Text("Lightning")
                        .font(.headline)
                    Text("v0.1.0")
                        .foregroundColor(.secondary)
                }
                Text("A fast macOS application launcher.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 350)
    }

    private func updateLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update login item: \(error)")
        }
    }
}
