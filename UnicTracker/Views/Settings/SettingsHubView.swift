import SwiftUI
import UIKit
import UniformTypeIdentifiers

public struct SettingsHubView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: DataStore

    @State private var showSemesterEdit: Bool = false
    @State private var showSubjectEdit: Bool = false
    @State private var selectedSubjectToEdit: Subject? = nil
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
                // MARK: - Section: Semester & Subjects Constructor
                Section("Конструктор семестра и предметов") {
                    Button {
                        showSemesterEdit = true
                        HapticManager.shared.touchGlass()
                    } label: {
                        HStack {
                            Label(store.activeSemester?.title ?? "Создать семестр", systemImage: "calendar.badge.clock")
                            Spacer()
                            Image(systemName: "pencil")
                                .foregroundColor(.cyan)
                        }
                    }

                    Button {
                        selectedSubjectToEdit = nil
                        showSubjectEdit = true
                        HapticManager.shared.touchGlass()
                    } label: {
                        Label("Добавить предмет / сгенерировать лабы", systemImage: "plus.circle.fill")
                            .foregroundColor(.cyan)
                    }

                    if !store.activeSubjects.isEmpty {
                        ForEach(store.activeSubjects) { subject in
                            Button {
                                selectedSubjectToEdit = subject
                                showSubjectEdit = true
                                HapticManager.shared.touchGlass()
                            } label: {
                                HStack(spacing: 8) {
                                    Text(subject.shortCode)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(subject.themeColor)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(RoundedRectangle(cornerRadius: 4).fill(subject.themeColor.opacity(0.18)))

                                    Text(subject.name)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    Spacer()

                                    Circle()
                                        .fill(subject.importance.color)
                                        .frame(width: 6, height: 6)

                                    Text(subject.importance.rawValue)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(subject.importance.color)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for idx in indexSet {
                                store.deleteSubject(store.activeSubjects[idx])
                            }
                        }
                    }
                }

                // MARK: - Section: Archive Lifecycle
                Section("Завершение семестра и архив") {
                    Button {
                        showFinishSemester = true
                        HapticManager.shared.touchGlass()
                    } label: {
                        Label("Завершить семестр и архивировать", systemImage: "archivebox.fill")
                            .foregroundColor(.purple)
                    }
                    .disabled(store.activeSemester == nil)

                    NavigationLink {
                        ArchiveHistoryView(store: store)
                    } label: {
                        HStack {
                            Label("Архив семестров", systemImage: "clock.arrow.circlepath")
                            Spacer()
                            Text("\(store.archivedSemesters.count)")
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }

                // MARK: - Section: Backup & JSON Export/Import
                Section("Резервная копия (JSON)") {
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
                        Label("Экспорт базы данных (JSON)", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showDocumentPicker = true
                        HapticManager.shared.touchGlass()
                    } label: {
                        Label("Импорт базы данных (JSON)", systemImage: "square.and.arrow.down")
                    }
                }

                // MARK: - Section: Theme & Appearance
                Section("Оформление Liquid Glass") {
                    Picker("Цветовая тема", selection: $store.theme.preset) {
                        ForEach(LiquidThemePreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .onChange(of: store.theme.preset) {
                        store.persist()
                    }

                    Toggle("Тактильный отклик (Haptics)", isOn: $store.theme.enableHaptics)
                        .onChange(of: store.theme.enableHaptics) {
                            store.persist()
                        }
                }

                // MARK: - Section: Database Management
                Section("База данных") {
                    Button {
                        store.loadSampleData()
                        dismiss()
                    } label: {
                        Label("Загрузить демонстрационные данные", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.yellow)
                    }

                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Очистить все данные", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }

                // MARK: - Section: App Info
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("UnicTracker • Liquid Glass")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                            Text("Локальное хранилище данных")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.35))
                        }
                        Spacer()
                    }
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
            .sheet(isPresented: $showSubjectEdit) {
                SubjectEditView(store: store, subjectToEdit: selectedSubjectToEdit)
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
