import SwiftUI
import UIKit
import UniformTypeIdentifiers

public struct SettingsHubView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: DataStore

    @State private var showSemesterEdit: Bool = false
    @State private var showFinishSemester: Bool = false
    @State private var showArchiveHistory: Bool = false

    @State private var exportURL: URL? = nil
    @State private var showShareSheet: Bool = false
    @State private var showDocumentPicker: Bool = false
    @State private var importedDataPreview: AppBackupData? = nil
    @State private var showResetAlert: Bool = false
    @State private var importErrorMessage: String? = nil
    @State private var showImportErrorAlert: Bool = false

    public init(store: DataStore) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - Section 1: Academic Semester
                Section {
                    if let sem = store.activeSemester {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(sem.title)
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)

                                    Text("\(sem.courseNumber) курс • \(sem.academicYear)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button {
                                    showSemesterEdit = true
                                    HapticManager.shared.touchGlass()
                                } label: {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(.cyan)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }

                            Divider()

                            HStack {
                                Label("Сроки:", systemImage: "calendar")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(sem.startDate.formatted(date: .abbreviated, time: .omitted)) – \(sem.endDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.system(size: 13, weight: .medium))
                            }

                            HStack {
                                Label("До завершения:", systemImage: "clock")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(sem.daysRemainingToEnd) дн.")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.cyan)
                            }
                        }
                        .padding(.vertical, 4)

                        Button {
                            showFinishSemester = true
                            HapticManager.shared.touchGlass()
                        } label: {
                            Label("Завершить семестр и в архив", systemImage: "archivebox.fill")
                                .foregroundColor(.purple)
                        }
                    } else {
                        Button {
                            showSemesterEdit = true
                            HapticManager.shared.touchGlass()
                        } label: {
                            Label("Создать семестр", systemImage: "plus.circle.fill")
                                .foregroundColor(.cyan)
                        }
                    }
                } header: {
                    Text("Учебный семестр")
                }

                // MARK: - Section 2: Appearance & Theme
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Режим оформления")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)

                        Picker("Режим темы", selection: $store.theme.themeMode) {
                            ForEach(AppThemeMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: store.theme.themeMode) {
                            store.persist()
                        }
                    }
                    .padding(.vertical, 2)

                    Picker("Цветовая палитра", selection: $store.theme.preset) {
                        ForEach(LiquidThemePreset.allCases) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }
                    .onChange(of: store.theme.preset) {
                        store.persist()
                    }

                    Toggle("Тактильный отклик (Haptics)", isOn: $store.theme.enableHaptics)
                        .onChange(of: store.theme.enableHaptics) {
                            store.persist()
                        }

                    Toggle("Мягкое свечение фона", isOn: $store.theme.enableAmbientGlow)
                        .onChange(of: store.theme.enableAmbientGlow) {
                            store.persist()
                        }
                } header: {
                    Text("Внешний вид и тема")
                } footer: {
                    Text("В системном режиме интерфейс автоматически следует настройкам темы iOS (светлая/темная).")
                }

                // MARK: - Section 3: History & Archive
                Section {
                    NavigationLink {
                        ArchiveHistoryView(store: store)
                    } label: {
                        HStack {
                            Label("Архив прошлых семестров", systemImage: "clock.arrow.circlepath")
                            Spacer()
                            Text("\(store.archivedSemesters.count)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("История")
                }

                // MARK: - Section 4: Data & Backup
                Section {
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
                            Label("Экспорт базы данных (JSON)", systemImage: "square.and.arrow.up")
                            Spacer()
                            Text("\(store.activeTasks.count) заданий")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        showDocumentPicker = true
                        HapticManager.shared.touchGlass()
                    } label: {
                        Label("Импорт из JSON файла", systemImage: "square.and.arrow.down")
                    }

                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Очистить все данные", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("Данные и резервные копии")
                } footer: {
                    Text("Экспортируйте JSON для сохранения резервной копии перед обновлением или переноса на другое устройство.")
                }

                // MARK: - Section 5: App Information
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "graduationcap.circle.fill")
                            .font(.system(size: 34))
                            .foregroundColor(.cyan)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("UnicTracker")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                            Text("Версия 2.1 • Автономное локальное хранилище")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.cyan)
                }
            }
            .sheet(isPresented: $showSemesterEdit) {
                SemesterEditView(store: store)
            }
            .sheet(isPresented: $showFinishSemester) {
                FinishSemesterModal(store: store)
            }
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
            .alert("Сбросить все данные?", isPresented: $showResetAlert) {
                Button("Сбросить", role: .destructive) {
                    store.resetAll()
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Все локальные предметы, семестры и история будут удалены.")
            }
        }
    }
}

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

private struct IdentifiableBackup: Identifiable {
    let id = UUID()
    let data: AppBackupData
}
