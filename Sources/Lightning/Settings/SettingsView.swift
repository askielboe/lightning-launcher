import SwiftUI
import ServiceManagement

/// Settings window UI for Lightning.
struct SettingsView: View {
    @State private var maxResults: Double
    @State private var launchAtLogin: Bool
    @State private var showSearchIcon: Bool
    @State private var additionalPaths: [String]
    @State private var removedDefaultPaths: Set<String>
    @State private var showPathPicker = false

    init() {
        let prefs = UserPreferences.shared
        _maxResults = State(initialValue: Double(prefs.maxResults))
        _launchAtLogin = State(initialValue: prefs.launchAtLogin)
        _showSearchIcon = State(initialValue: prefs.showSearchIcon)
        _additionalPaths = State(initialValue: prefs.additionalSearchPaths)
        _removedDefaultPaths = State(initialValue: Set(prefs.removedDefaultPaths))
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("General") {
                    HotKeyRecorderView()

                    Toggle("Launch at login", isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { newValue in
                            UserPreferences.shared.launchAtLogin = newValue
                            updateLoginItem(enabled: newValue)
                        }

                    Toggle("Show lightning icon in search field", isOn: $showSearchIcon)
                        .onChange(of: showSearchIcon) { newValue in
                            UserPreferences.shared.showSearchIcon = newValue
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
                    ForEach(AppScanner.defaultSearchPaths.filter { !removedDefaultPaths.contains($0.path) }, id: \.path) { url in
                        HStack {
                            Text(url.path)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(role: .destructive) {
                                removedDefaultPaths.insert(url.path)
                                UserPreferences.shared.removedDefaultPaths = Array(removedDefaultPaths)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.borderless)
                        }
                    }

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

                    HStack {
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

                        if !removedDefaultPaths.isEmpty {
                            Spacer()
                            Button("Restore Defaults") {
                                removedDefaultPaths.removeAll()
                                UserPreferences.shared.removedDefaultPaths = []
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11))
                Text("Lightning \(appVersion)")
                    .font(.system(size: 11))
                Text(BuildInfo.gitCommit)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .foregroundColor(.secondary)
            .padding(.bottom, 12)
        }
        .frame(width: 500, height: 520)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
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
