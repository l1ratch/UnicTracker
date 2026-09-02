import SwiftUI

public struct MainTrackerView: View {
    @ObservedObject var store: DataStore
    public var onOpenSettings: () -> Void

    @State private var selectedTaskForDetail: StudyTask? = nil
    @State private var selectedSubjectForNewTask: UUID? = nil
    @State private var showTaskCreateSheet: Bool = false
    @State private var showSubjectCreateSheet: Bool = false

    public init(store: DataStore, onOpenSettings: @escaping () -> Void) {
        self.store = store
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        ZStack {
            // Subtle dark background with gentle glass glow
            LinearGradient(
                colors: store.theme.preset.backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // MARK: - Compact Top Bar (Progress & Session Countdown)
                    compactTopSummary

                    // MARK: - Section 1: Disciplines & Tasks
                    studyDisciplinesSection

                    // MARK: - Section 2: Session & Exams (Inline grading)
                    if !store.activeSubjects.isEmpty {
                        sessionGradingSection
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
            }
        }
        .navigationTitle(store.activeSemester?.title ?? "Трекер")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    HapticManager.shared.touchGlass()
                    onOpenSettings()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
        }
        .sheet(item: $selectedTaskForDetail) { task in
            TaskDetailSheet(store: store, task: task)
        }
        .sheet(isPresented: $showTaskCreateSheet) {
            TaskEditView(store: store, defaultSubjectId: selectedSubjectForNewTask)
        }
        .sheet(isPresented: $showSubjectCreateSheet) {
            SubjectEditView(store: store)
        }
    }

    // MARK: - Compact Top Summary Bar
    private var compactTopSummary: some View {
        HStack(spacing: 10) {
            // Overall Progress Bar & Percentage
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Успеваемость")
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

            // Countdown to Session
            if let sem = store.activeSemester {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 13))
                        .foregroundColor(.cyan)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("До сессии")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        Text("\(sem.daysRemainingToSession) дн.")
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

    // MARK: - Section 1: Study Disciplines & Tasks List
    private var studyDisciplinesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ПРЕДМЕТЫ И РАБОТЫ")
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
                    compactSubjectCard(subject: subject)
                }
            }
        }
    }

    // MARK: - Compact Subject Card with Inline Tasks
    private func compactSubjectCard(subject: Subject) -> some View {
        let subjectTasks = store.tasks.filter { $0.subjectId == subject.id }
        let completedCount = subjectTasks.filter { $0.status.isFinished }.count
        let progress = subjectTasks.isEmpty ? 0.0 : Double(completedCount) / Double(subjectTasks.count)

        return VStack(alignment: .leading, spacing: 8) {
            // Subject Header Row
            HStack(spacing: 8) {
                Circle()
                    .fill(subject.themeColor)
                    .frame(width: 8, height: 8)

                Text(subject.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(subject.assessmentType.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(subject.assessmentType.badgeColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(subject.assessmentType.badgeColor.opacity(0.15)))

                Spacer()

                Text("\(completedCount)/\(subjectTasks.count)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                // Quick add task to this subject
                Button {
                    selectedSubjectForNewTask = subject.id
                    showTaskCreateSheet = true
                    HapticManager.shared.touchGlass()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(subject.themeColor.opacity(0.9))
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Thin Subject Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 3)
                    Capsule()
                        .fill(subject.themeColor)
                        .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(progress))), height: 3)
                }
            }
            .frame(height: 3)

            // Inline Task Rows
            if subjectTasks.isEmpty {
                Text("Нет добавленных заданий")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.vertical, 2)
            } else {
                VStack(spacing: 4) {
                    ForEach(subjectTasks) { task in
                        compactTaskRow(task: task)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.09), lineWidth: 0.8)
                )
        )
    }

    // MARK: - Compact Inline Task Row
    private func compactTaskRow(task: StudyTask) -> some View {
        HStack(spacing: 8) {
            // Checkbox Button
            Button {
                store.toggleTaskCompletion(task)
            } label: {
                Image(systemName: task.status.isFinished ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(task.status.isFinished ? .green : .white.opacity(0.3))
            }
            .buttonStyle(PlainButtonStyle())

            // Task Title
            Button {
                selectedTaskForDetail = task
                HapticManager.shared.touchGlass()
            } label: {
                HStack(spacing: 6) {
                    Text(task.title)
                        .font(.system(size: 13, weight: task.status.isFinished ? .regular : .medium))
                        .foregroundColor(task.status.isFinished ? .white.opacity(0.35) : .white.opacity(0.9))
                        .strikethrough(task.status.isFinished, color: .white.opacity(0.3))
                        .lineLimit(1)

                    if !task.subtasks.isEmpty {
                        let subDone = task.subtasks.filter { $0.isCompleted }.count
                        Text("(\(subDone)/\(task.subtasks.count))")
                            .font(.system(size: 11))
                            .foregroundColor(.cyan.opacity(0.8))
                    }

                    Spacer()

                    // Priority Dot
                    Circle()
                        .fill(task.priority.color)
                        .frame(width: 5, height: 5)

                    // Due Date Tag
                    if let due = task.dueDate {
                        Text(formatCompactDate(due))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(due < Date() && !task.status.isFinished ? .red : .white.opacity(0.4))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 3)
    }

    // MARK: - Section 2: Session & Inline Exams / Tests Grading
    private var sessionGradingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("СЕССИЯ И АТТЕСТАЦИЯ")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                if let gpa = sessionAverageGPA {
                    Text("Средний балл: \(gpa)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)

            VStack(spacing: 8) {
                ForEach(store.activeSubjects) { subject in
                    compactSessionSubjectRow(subject: subject)
                }
            }
        }
    }

    // MARK: - Compact Session Subject Row (1-Tap Grading)
    private func compactSessionSubjectRow(subject: Subject) -> some View {
        let sessionItem = store.getSessionItem(for: subject.id)
        let isExam = subject.assessmentType == .exam || subject.assessmentType == .diffTest

        return HStack(spacing: 10) {
            // Admission Checkbox
            Button {
                store.toggleAdmission(for: subject.id)
            } label: {
                Image(systemName: subject.isAdmittedToExam ? "checkmark.shield.fill" : "shield")
                    .font(.system(size: 16))
                    .foregroundColor(subject.isAdmittedToExam ? .green : .white.opacity(0.3))
            }
            .buttonStyle(PlainButtonStyle())

            // Subject Name & Type
            VStack(alignment: .leading, spacing: 2) {
                Text(subject.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(subject.assessmentType.rawValue)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Inline Quick Grading Buttons
            if isExam {
                HStack(spacing: 4) {
                    ForEach([2, 3, 4, 5], id: \.self) { gradeVal in
                        let isSelected = sessionItem?.grade?.rawValue == gradeVal
                        Button {
                            var item = sessionItem ?? SessionItem(subjectId: subject.id)
                            item.grade = isSelected ? nil : ExamGrade(rawValue: gradeVal)
                            store.updateSessionItem(item)
                            HapticManager.shared.touchGlass()
                        } label: {
                            Text("\(gradeVal)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                                .frame(width: 26, height: 26)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isSelected ? gradeColor(for: gradeVal) : Color.white.opacity(0.06))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            } else {
                // Test (Зачет / Незачет) 1-Tap Toggle
                let isPassed = sessionItem?.testResult == .passed
                Button {
                    var item = sessionItem ?? SessionItem(subjectId: subject.id)
                    item.testResult = isPassed ? .failed : .passed
                    store.updateSessionItem(item)
                    HapticManager.shared.touchGlass()
                } label: {
                    Text(isPassed ? "Сдал" : "Не сдал")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(isPassed ? .green : .white.opacity(0.5))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(isPassed ? Color.green.opacity(0.18) : Color.white.opacity(0.06))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.8)
                )
        )
    }

    private func gradeColor(for grade: Int) -> Color {
        switch grade {
        case 5: return Color.green
        case 4: return Color.blue
        case 3: return Color.orange
        default: return Color.red
        }
    }

    private var sessionAverageGPA: String? {
        let grades = store.activeSessionItems.compactMap { $0.grade?.rawValue }
        guard !grades.isEmpty else { return nil }
        let avg = Double(grades.reduce(0, +)) / Double(grades.count)
        return String(format: "%.2f", avg)
    }

    private func formatCompactDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "dd.MM"
        return df.string(from: date)
    }

    private var emptySubjectsPrompt: some View {
        VStack(spacing: 8) {
            Text("Список предметов пуст")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

            Text("Нажмите «+ Предмет» или откройте настройки для загрузки демо-данных.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
        )
    }
}
