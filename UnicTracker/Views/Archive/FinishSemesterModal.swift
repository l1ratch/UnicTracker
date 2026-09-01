import SwiftUI

public struct FinishSemesterModal: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: DataStore

    @State private var archiveNotes: String = ""
    @State private var createNextSemesterAuto: Bool = true
    @State private var nextSemesterTitle: String = ""

    public init(store: DataStore) {
        self.store = store
        let currentSemNum = store.activeSemester?.semesterNumber ?? 1
        let nextSemNum = currentSemNum + 1
        let nextCourse = (nextSemNum + 1) / 2
        self._nextSemesterTitle = State(initialValue: "\(nextCourse) Курс • \(nextSemNum % 2 == 1 ? "Осенний" : "Весенний") семестр")
    }

    public var body: some View {
        NavigationView {
            ZStack {
                MeshGradientBackground(store: store)

                ScrollView {
                    VStack(spacing: 20) {
                        // Celebration Glass Header
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 40))
                                .foregroundColor(.yellow)
                                .shadow(color: .yellow.opacity(0.8), radius: 10)

                            Text("Завершение семестра")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)

                            Text("Поздравляем с закрытием сессии! Все оценки и статистика будут надежно зафиксированы в истории.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 10)
                        }
                        .padding(20)
                        .liquidGlass(cornerRadius: 24, depth: store.theme.glassDepth, tint: Color.yellow)

                        // Stats Summary Preview
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ИТОГИ СЕМЕСТРА")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))

                            HStack(spacing: 12) {
                                statTile(title: "Выполнено заданий", value: "\(store.completedTasksCount)/\(store.totalTasksCount)", tint: .cyan)
                                statTile(title: "Прогресс", value: "\(store.overallProgressPercentage)%", tint: .green)
                            }
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)

                        // Notes card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ЗАМЕТКИ И ВПЕЧАТЛЕНИЯ")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))

                            TextField("Как прошел семестр? Что было сложным/легким...", text: $archiveNotes, axis: .vertical)
                                .lineLimit(3...5)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)

                        // Auto-create next semester toggle
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Сразу открыть новый семестр", isOn: $createNextSemesterAuto)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)

                            if createNextSemesterAuto {
                                TextField("Название следующего семестра", text: $nextSemesterTitle)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                            }
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth, tint: Color.purple)

                        // Confirm Button
                        Button {
                            finishAndProceed()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Архивировать и сохранить")
                            }
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(GlassButtonStyle(tint: Color.green, cornerRadius: 18, isProminent: true))
                        .padding(.top, 10)

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Архивация")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }

    private func statTile(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }

    private func finishAndProceed() {
        let currentSem = store.activeSemester
        let currentNum = currentSem?.semesterNumber ?? 1

        store.finishAndArchiveActiveSemester(notes: archiveNotes)

        if createNextSemesterAuto {
            let nextNum = currentNum + 1
            let nextCourse = (nextNum + 1) / 2
            let cal = Calendar.current
            let now = Date()
            let newEnd = cal.date(byAdding: .month, value: 5, to: now) ?? now
            let newSession = cal.date(byAdding: .month, value: 4, to: now)

            store.createSemester(
                title: nextSemesterTitle.isEmpty ? "Семестр \(nextNum)" : nextSemesterTitle,
                course: nextCourse,
                semesterNumber: nextNum,
                startDate: now,
                endDate: newEnd,
                sessionStart: newSession
            )
        }

        dismiss()
    }
}
