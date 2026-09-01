import SwiftUI

public struct ArchiveHistoryView: View {
    @ObservedObject var store: DataStore

    public init(store: DataStore) {
        self.store = store
    }

    public var body: some View {
        NavigationView {
            ZStack {
                MeshGradientBackground(store: store)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        if store.archivedSemesters.isEmpty {
                            emptyArchiveView
                        } else {
                            ForEach(store.archivedSemesters) { semester in
                                archivedSemesterCard(semester: semester)
                            }
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Архив семестров")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func archivedSemesterCard(semester: Semester) -> some View {
        let summary = semester.archivedSummary
        let semSubjects = store.subjects.filter { $0.semesterId == semester.id }

        return VStack(alignment: .leading, spacing: 14) {
            // Header: Title & Archived date
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(semester.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    if let archivedAt = semester.archivedAt {
                        Text("Архивирован: \(archivedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                if let gpa = summary?.averageGrade {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Ср. балл")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                        Text(String(format: "%.2f", gpa))
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(.yellow)
                    }
                }
            }

            Divider().background(Color.white.opacity(0.1))

            // Stats grid
            HStack(spacing: 10) {
                archiveStatPill(
                    icon: "checklist",
                    label: "Заданий",
                    value: "\(summary?.completedTasksCount ?? 0)/\(summary?.totalTasksCount ?? 0)"
                )

                archiveStatPill(
                    icon: "graduationcap.fill",
                    label: "Экзамены",
                    value: "\(summary?.passedExamsCount ?? 0)/\(summary?.totalExamsCount ?? 0)"
                )

                archiveStatPill(
                    icon: "checkmark.seal.fill",
                    label: "Зачеты",
                    value: "\(summary?.passedTestsCount ?? 0)/\(summary?.totalTestsCount ?? 0)"
                )
            }

            // Subject tags list
            if !semSubjects.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Изученные дисциплины:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(semSubjects) { sub in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(sub.themeColor)
                                        .frame(width: 6, height: 6)
                                    Text(sub.name)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.white.opacity(0.06)))
                            }
                        }
                    }
                }
            }

            // Notes if any
            if let notes = summary?.archiveNote, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Заметки:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    Text(notes)
                        .font(.system(size: 13))
                        .italic()
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20, depth: store.theme.glassDepth)
    }

    private func archiveStatPill(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.cyan)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
    }

    private var emptyArchiveView: some View {
        VStack(spacing: 14) {
            Image(systemName: "archivebox")
                .font(.system(size: 46))
                .foregroundColor(.white.opacity(0.4))
            Text("Архив пуст")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Когда вы завершите текущий семестр через вкладку «Сессия», он автоматически сохранится здесь со всеми оценками и статистикой.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(28)
        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)
        .padding(.top, 30)
    }
}
