import SwiftUI

public struct MainTrackerView: View {
    @ObservedObject var store: DataStore
    public var onOpenSettings: () -> Void

    @State private var showSubjectCreateSheet: Bool = false
    @State private var showTaskCreateSheet: Bool = false
    @State private var selectedSubjectForNewTask: UUID? = nil

    public init(store: DataStore, onOpenSettings: @escaping () -> Void) {
        self.store = store
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: store.theme.preset.backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    // MARK: - Top Summary Mini Bar (Semester Progress & End Countdown)
                    compactTopSummary

                    // MARK: - Subject Cards List (Sorted by Importance)
                    subjectCardsSection

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
            }
        }
        .navigationTitle(store.activeSemester?.title ?? "Трекер практик")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    HapticManager.shared.touchGlass()
                    onOpenSettings()
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .sheet(isPresented: $showSubjectCreateSheet) {
            SubjectEditView(store: store)
        }
        .sheet(isPresented: $showTaskCreateSheet) {
            TaskEditView(store: store, defaultSubjectId: selectedSubjectForNewTask)
        }
    }

    // MARK: - Compact Top Summary Bar
    private var compactTopSummary: some View {
        HStack(spacing: 12) {
            // Overall Progress Bar & Percentage
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Общий прогресс сдачи")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("\(store.overallProgressPercentage)%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(store.theme.preset.primaryAccent)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 5)
                        Capsule()
                            .fill(store.theme.preset.primaryAccent)
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(store.overallProgressPercentage) / 100.0)), height: 5)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 24)
                .background(Color.white.opacity(0.15))

            // Countdown to End of Semester
            if let sem = store.activeSemester {
                HStack(spacing: 6) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 13))
                        .foregroundColor(.cyan)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("До конца")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        Text("\(sem.daysRemainingToEnd) дн.")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
                )
        )
    }

    // MARK: - Section: Subject Cards List (Prioritized by Importance)
    private var subjectCardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ПРЕДМЕТЫ И ПРАКТИКИ")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                Button {
                    showSubjectCreateSheet = true
                    HapticManager.shared.touchGlass()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                        Text("Предмет")
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(store.theme.preset.primaryAccent)
                }
            }
            .padding(.horizontal, 4)

            if store.activeSubjects.isEmpty {
                emptySubjectsPrompt
            } else {
                ForEach(store.activeSubjects) { subject in
                    subjectCard(subject: subject)
                }
            }
        }
    }

    // MARK: - Single Subject Card (Short Code prominent + Importance + Inline Tasks)
    private func subjectCard(subject: Subject) -> some View {
        let subjectTasks = store.tasks.filter { $0.subjectId == subject.id }
        let completedCount = subjectTasks.filter { $0.status.isFinished }.count
        let progress = subjectTasks.isEmpty ? 0.0 : Double(completedCount) / Double(subjectTasks.count)

        return NavigationLink {
            SubjectDetailView(store: store, subjectId: subject.id)
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                // Top Row: Short Code Badge (Large/Bold) + Full Name + Importance Badge
                HStack(spacing: 8) {
                    // Short Code Tag
                    Text(subject.shortCode)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(subject.themeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(subject.themeColor.opacity(0.18))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .strokeBorder(subject.themeColor.opacity(0.4), lineWidth: 0.8)
                                )
                        )

                    // Full Subject Name
                    Text(subject.name)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer()

                    // Importance Badge (🔴 🟠 🟡 🟢)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(subject.importance.color)
                            .frame(width: 6, height: 6)

                        Text(subject.importance.rawValue)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(subject.importance.color)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(subject.importance.color.opacity(0.12))
                    )

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }

                // Thin Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 4)
                        Capsule()
                            .fill(subject.themeColor)
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(progress))), height: 4)
                    }
                }
                .frame(height: 4)

                // Quick stats: Practices done + Attendance summary
                HStack(spacing: 10) {
                    Text("Практик: \(completedCount)/\(subjectTasks.count)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))

                    Text("•")
                        .foregroundColor(.white.opacity(0.25))

                    Text("Лекции: \(subject.lecturesAttended)/\(subject.lecturesTotal)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue.opacity(0.9))

                    Text("•")
                        .foregroundColor(.white.opacity(0.25))

                    Text("Практики: \(subject.practicesAttended)/\(subject.practicesTotal)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green.opacity(0.9))

                    Spacer()
                }

                // Inline tasks preview (first 3 tasks with direct checkmark toggles)
                if !subjectTasks.isEmpty {
                    Divider().background(Color.white.opacity(0.06))

                    VStack(spacing: 4) {
                        ForEach(subjectTasks.prefix(3)) { task in
                            HStack(spacing: 6) {
                                Button {
                                    store.toggleTaskCompletion(task)
                                } label: {
                                    Image(systemName: task.status.isFinished ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 14))
                                        .foregroundColor(task.status.isFinished ? .green : .white.opacity(0.35))
                                }
                                .buttonStyle(PlainButtonStyle())

                                Text(task.title)
                                    .font(.system(size: 12, weight: task.status.isFinished ? .regular : .medium))
                                    .foregroundColor(task.status.isFinished ? .white.opacity(0.35) : .white.opacity(0.85))
                                    .strikethrough(task.status.isFinished, color: .white.opacity(0.3))
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(.vertical, 1)
                        }

                        if subjectTasks.count > 3 {
                            Text("+ еще \(subjectTasks.count - 3) заданий...")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.cyan.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.8)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var emptySubjectsPrompt: some View {
        VStack(spacing: 8) {
            Text("Список предметов пуст")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

            Text("Нажмите «+ Предмет» или откройте меню «...» вверху для загрузки демо-данных.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))
    }
}
