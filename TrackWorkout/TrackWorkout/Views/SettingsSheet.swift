import SwiftUI
import CoreData
import UniformTypeIdentifiers

enum SettingsKey {
    static let syncEnabled = "sync.enabled"
    static let syncEndpoint = "sync.endpoint"
    static let authToken = "authToken"
}

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @AppStorage(SettingsKey.syncEnabled) private var syncEnabled: Bool = false
    @AppStorage(SettingsKey.syncEndpoint) private var endpoint: String = ""
    @AppStorage(SettingsKey.authToken) private var authToken: String = ""

    @State private var testResult: String?
    @State private var testing = false
    @State private var hrImportResult: String?
    @State private var showingFileImporter = false
    @State private var fileImportError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Sync to remote server", isOn: $syncEnabled)
                        .accessibilityIdentifier("settings-sync-toggle")
                } footer: {
                    Text("When off, workouts are saved locally only. The app works fully offline.")
                }

                if syncEnabled {
                    Section("Endpoint") {
                        TextField("https://your-server.example.com/sync/events", text: $endpoint)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .keyboardType(.URL)
                            .accessibilityIdentifier("settings-endpoint-field")
                    }

                    Section("API key") {
                        SecureField("API key", text: $authToken)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .accessibilityIdentifier("settings-apikey-field")
                    }

                    Section {
                        Button(action: testConnection) {
                            HStack {
                                Text(testing ? "Testing…" : "Test connection")
                                Spacer()
                                if let result = testResult {
                                    Text(result)
                                        .font(.caption)
                                        .foregroundColor(result.hasPrefix("OK") ? .green : .red)
                                }
                            }
                        }
                        .disabled(testing || endpoint.isEmpty)
                        .accessibilityIdentifier("settings-test-button")
                    }
                }

                Section {
                    Button(action: { showingFileImporter = true }) {
                        HStack {
                            Text("Import HR CSV from file…")
                            Spacer()
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.secondary)
                        }
                    }
                    .accessibilityIdentifier("settings-import-hr-file")

                    Button(action: importDemoHR) {
                        HStack {
                            Text("Import demo HR data")
                            Spacer()
                            if let result = hrImportResult {
                                Text(result)
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .accessibilityIdentifier("settings-import-demo-hr")

                    if let err = fileImportError {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Heart rate")
                } footer: {
                    Text("Expected columns: timestamp, heart_rate_bpm (required). Optional: elevation_m, speed_kmh, distance_km. See DATA_MODEL.md § CSV Import Schema in track-workout-core.")
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.commaSeparatedText, .text, .plainText, .data],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("settings-done")
                }
            }
        }
    }

    private func testConnection() {
        guard let url = healthURL(from: endpoint) else {
            testResult = "Invalid URL"
            return
        }
        testing = true
        testResult = nil
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse else {
                    await MainActor.run {
                        testResult = "No response"
                        testing = false
                    }
                    return
                }
                if (200...299).contains(http.statusCode) {
                    let bodyPreview = String(data: data, encoding: .utf8)?.prefix(40) ?? ""
                    await MainActor.run {
                        testResult = "OK \(http.statusCode) \(bodyPreview)"
                        testing = false
                    }
                } else {
                    await MainActor.run {
                        testResult = "HTTP \(http.statusCode)"
                        testing = false
                    }
                }
            } catch {
                await MainActor.run {
                    testResult = "Error: \(error.localizedDescription)"
                    testing = false
                }
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        fileImportError = nil
        switch result {
        case .failure(let err):
            fileImportError = "Could not open file: \(err.localizedDescription)"
            return
        case .success(let urls):
            guard let url = urls.first else {
                fileImportError = "No file selected"
                return
            }
            // Files from other apps (Files.app, iCloud Drive) come with
            // security-scoped URLs that need explicit access.
            let needsRelease = url.startAccessingSecurityScopedResource()
            defer {
                if needsRelease { url.stopAccessingSecurityScopedResource() }
            }
            do {
                let data = try Data(contentsOf: url)
                guard let csv = String(data: data, encoding: .utf8) else {
                    fileImportError = "File is not valid UTF-8"
                    return
                }
                let (parsed, skipped) = HRImporter.parse(csv)
                let source = "file:" + url.lastPathComponent
                let importResult = HRImporter.persistAndAlign(
                    parsed,
                    source: source,
                    userId: UUID(),
                    in: viewContext
                )
                hrImportResult = "\(importResult.persisted) samples, \(importResult.aligned) aligned" +
                    (skipped > 0 ? " · \(skipped) rows skipped" : "")
            } catch {
                fileImportError = "Read failed: \(error.localizedDescription)"
            }
        }
    }

    private func importDemoHR() {
        let csv = HRFixture.syntheticCSV(seconds: 60)
        let (parsed, _) = HRImporter.parse(csv)
        // Use a nil-safe placeholder for userId until single-user is threaded.
        let userId = UUID()
        let result = HRImporter.persistAndAlign(
            parsed,
            source: "demo-fixture",
            userId: userId,
            in: viewContext
        )
        hrImportResult = "\(result.persisted) samples, \(result.aligned) aligned"
    }

    /// Replace `/sync/events` with `/health` for the connectivity probe.
    private func healthURL(from endpoint: String) -> URL? {
        let trimmed = endpoint.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else { return nil }
        let healthString = trimmed.replacingOccurrences(of: "/sync/events", with: "/health")
        return URL(string: healthString) ?? url
    }
}

#Preview {
    SettingsSheet()
}
