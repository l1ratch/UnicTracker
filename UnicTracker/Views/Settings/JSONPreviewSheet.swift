import SwiftUI

public struct JSONPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: DataStore
    public var importedData: AppBackupData

    public init(store: DataStore, importedData: AppBackupData) {
        self.store = store
        self.importedData = importedData
    }

    public var body: some View {
        NavigationView {
            ZStack {
                MeshGradientBackground(store: store)

                ScrollView {
                    VStack(spacing: 20) {
                        // Success header
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 38))
                                .foregroundColor(.green)

                            Text("Файл резервной копии проверен")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Версия схемы: \(importedData.version)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth, tint: Color.green)

                        // Data Breakdown
                        VStack(alignment: .leading, spacing: 14) {
                            Text("СОДЕРЖИМОЕ ИМПОРТА")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))

                            statRow(title: "Семестров", value: "\(importedData.semesters.count)")
                            statRow(title: "Дисциплин", value: "\(importedData.subjects.count)")
                            statRow(title: "Заданий и лабораторных", value: "\(importedData.tasks.count)")
                            statRow(title: "Аттестаций сессии", value: "\(importedData.sessionItems.count)")
                            statRow(title: "Тема оформления", value: importedData.themeSettings.preset.displayName)
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)

                        // Warning
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 18))

                            Text("Применение импорта заменит текущие локальные данные на данные из выбранного файла.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(14)
                        .liquidGlass(cornerRadius: 16, depth: store.theme.glassDepth, tint: Color.orange)

                        // Apply Button
                        Button {
                            store.applyImportedData(importedData)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.down.doc.fill")
                                Text("Применить и загрузить")
                            }
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(GlassButtonStyle(tint: Color.cyan, cornerRadius: 18, isProminent: true))

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Импорт данных")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.vertical, 3)
    }
}
