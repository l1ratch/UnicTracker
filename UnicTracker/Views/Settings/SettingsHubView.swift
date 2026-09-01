import SwiftUI
import UniformTypeIdentifiers

// MARK: - Activity / Share Sheet Helper
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Document Picker for JSON Import
struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (Data) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json, .data], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            do {
                let isAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if isAccessing { url.stopAccessingSecurityScopedResource() }
                }
                let data = try Data(contentsOf: url)
                parent.onPick(data)
            } catch {
                print("Error reading picked file: \(error)")
            }
        }
    }
}

// MARK: - Settings Hub View
public struct SettingsHubView: View {
    @ObservedObject var store: DataStore

    @State private var exportURL: URL? = nil
    @State private var showShareSheet: Bool = false
    @State private var showDocumentPicker: Bool = false
    @State private var importedDataPreview: AppBackupData? = nil
    @State private var showResetConfirm: Bool = false
    @State private var importErrorMessage: String? = nil
    @State private var showImportErrorAlert: Bool = false

    public init(store: DataStore) {
        self.store = store
    }

    public var body: some View {
        NavigationView {
            ZStack {
                MeshGradientBackground(store: store)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // MARK: - Liquid Glass Theme & Visuals
                        themeSection

                        // MARK: - Glass Depth & Physics
                        materialsSection

                        // MARK: - Export & Import Backup Hub
                        backupSection

                        // MARK: - Data Management & Demo Loader
                        dataManagementSection

                        // MARK: - Version & Info Footer
                        appInfoFooter

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Центр настроек")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ActivityView(activityItems: [url])
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker { rawData in
                    do {
                        let decoded = try StorageService.shared.importFromJSON(data: rawData)
                        self.importedDataPreview = decoded
                    } catch {
                        self.importErrorMessage = "Неверный формат JSON файла или несовместимая схема данных."
                        self.showImportErrorAlert = true
                    }
                }
            }
            .sheet(item: Binding(
                get: { importedDataPreview.map { IdentifiableBackup(data: $0) } },
                set: { importedDataPreview = $0?.data }
            )) { identifiable in
                JSONPreviewSheet(store: store, importedData: identifiable.data)
            }
            .alert("Ошибка импорта", isPresented: $showImportErrorAlert) {
                Button("ОК", role: .cancel) {}
            } message: {
                Text(importErrorMessage ?? "Не удалось прочитать файл.")
            }
            .alert("Сбросить все данные?", isPresented: $showResetConfirm) {
                Button("Сбросить все", role: .destructive) {
                    store.resetAll()
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Все ваши семестры, дисциплины, лабораторные работы и архивные записи будут удалены из локального хранилища.")
            }
        }
    }

    // MARK: - Theme Presets Section
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ЦВЕТОВАЯ ТЕМА LIQUID GLASS")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(LiquidThemePreset.allCases) { preset in
                    let isSelected = store.theme.preset == preset
                    Button {
                        store.theme.preset = preset
                        store.persist()
                        HapticManager.shared.touchGlass()
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [preset.primaryAccent, preset.secondaryAccent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 20, height: 20)
                                .shadow(color: preset.primaryAccent.opacity(0.7), radius: 3)

                            Text(preset.rawValue)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                                .lineLimit(1)

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isSelected ? preset.primaryAccent.opacity(0.25) : Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(isSelected ? preset.primaryAccent : Color.white.opacity(0.1), lineWidth: 1.2)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)
    }

    // MARK: - Materials & Physics Section
    private var materialsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("МАТЕРИАЛЫ И ЭФФЕКТЫ")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            VStack(spacing: 8) {
                ForEach(GlassMaterialDepth.allCases) { depth in
                    let isSelected = store.theme.glassDepth == depth
                    Button {
                        store.theme.glassDepth = depth
                        store.persist()
                        HapticManager.shared.touchGlass()
                    } label: {
                        HStack {
                            Text(depth.displayName)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.cyan)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            Divider().background(Color.white.opacity(0.1))

            Toggle("Динамический фоновый градиент", isOn: $store.theme.enableAmbientGlow)
                .foregroundColor(.white)
                .onChange(of: store.theme.enableAmbientGlow) { _, _ in
                    store.persist()
                }

            Toggle("Тактильный отклик (Haptics)", isOn: $store.theme.enableHaptics)
                .foregroundColor(.white)
                .onChange(of: store.theme.enableHaptics) { _, _ in
                    store.persist()
                }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)
    }

    // MARK: - Backup & Export Section
    private var backupSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ЭКСПОРТ И ИМПОРТ ДАННЫХ")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            Text("Все данные хранятся на устройстве. Вы можете выгрузить полный архив в JSON или восстановить его.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.65))

            HStack(spacing: 12) {
                // Export Button
                Button {
                    let backup = AppBackupData(
                        semesters: store.semesters,
                        subjects: store.subjects,
                        tasks: store.tasks,
                        sessionItems: store.sessionItems,
                        themeSettings: store.theme
                    )
                    if let url = StorageService.shared.exportToFileURL(data: backup) {
                        self.exportURL = url
                        self.showShareSheet = true
                        HapticManager.shared.touchGlass()
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Экспорт JSON")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(GlassButtonStyle(tint: Color.cyan, cornerRadius: 14, isProminent: true))

                // Import Button
                Button {
                    showDocumentPicker = true
                    HapticManager.shared.touchGlass()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("Импорт JSON")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(GlassButtonStyle(tint: Color.cyan.opacity(0.2), cornerRadius: 14))
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)
    }

    // MARK: - Data Management & Reset
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("УПРАВЛЕНИЕ ДАННЫМИ")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            Button {
                store.loadSampleData()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                    Text("Загрузить демонстрационный семестр")
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.yellow)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(GlassButtonStyle(tint: Color.yellow.opacity(0.2), cornerRadius: 14))

            Button {
                showResetConfirm = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Очистить все данные приложения")
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(GlassButtonStyle(tint: Color.red.opacity(0.2), cornerRadius: 14))
        }
        .padding(18)
        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)
    }

    // MARK: - App Info Footer
    private var appInfoFooter: some View {
        VStack(spacing: 6) {
            Text("UnicTracker • Liquid Glass Edition")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))

            Text("Версия 2.7 • Native iOS 26/27 Architecture")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))

            Text("Локальное хранилище данных • Готово для подписи в GBox")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }
}

// Wrapper struct for sheet presentation
private struct IdentifiableBackup: Identifiable {
    let id = UUID()
    let data: AppBackupData
}
