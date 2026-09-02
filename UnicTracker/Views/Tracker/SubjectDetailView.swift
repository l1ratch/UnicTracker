import SwiftUI

public struct SubjectDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: DataStore
    public var subjectId: UUID

    @State private var showTaskCreateSheet: Bool = false
    @State private var selectedTaskForEdit: StudyTask? = nil
    @State private var showBatchGenSheet: Bool = false
    @State private var showAttendanceEditor: Bool = false
    @State private var expandedTaskIds: Set<UUID> = []

    public init(store: DataStore, subjectId: UUID) {
        self.store = store
        self.subjectId = subjectId
    }

    private var subject: Subject? {
        store.getSubject(for: subjectId)
    }

    private var subjectTasks: [StudyTask] {
        store.tasks.filter { $0.subjectId == subjectId }
    }

    private var sessionItem: SessionItem? {
        store.getSessionItem(for: subjectId)
    }

    private var completedTasksCount: Int {
        subjectTasks.filter { $0.status.isFinished }.count
    }

    private var progressRatio: Double {
        guard !subjectTasks.isEmpty else { return 0.0 }
        let total = subjectTasks.reduce(0.0) { $0 + $1.completionRatio }
        return total / Double(subjectTasks.count)
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: store.theme.preset.backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if let sub = subject {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // MARK: - Subject Progress Header
                        subjectHeaderCard(sub: sub)

                        // MARK: - Compact Attendance Pod (Лекции и Практики)
                        attendancePod(sub: sub)

                        // MARK: - Session & Exam Status Card
                        sessionMiniCard(sub: sub)

                        // MARK: - Tasks & Practices List
                        tasksSection(sub: sub)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                }
            } else {
                Text("Дисциплина не найдена")
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .navigationTitle(subject?.name ?? "Дисциплина")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showTaskCreateSheet = true
                    HapticManager.shared.touchGlass()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(subject?.themeColor ?? .cyan)
                }
            }
        }
        .sheet(isPresented: $showTaskCreateSheet) {
            TaskEditView(store: store, defaultSubjectId: subjectId)
        }
        .sheet(item: $selectedTaskForEdit) { task in
            TaskDetailSheet(store: store, task: task)
        }
        .sheet(isPresented: $showAttendanceEditor) {
            if let sub = subject {
                AttendanceEditSheet(store: store, subject: sub)
            }
        }
    }

    // MARK: - Subject Header Card
    private func subjectHeaderCard(sub: Subject) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(sub.themeColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: sub.iconName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(sub.themeColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(sub.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    if !sub.teacherName.isEmpty || !sub.roomOrLink.isEmpty {
                        Text([sub.teacherName, sub.roomOrLink].filter { !$0.isEmpty }.joined(separator: " • "))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }

                Spacer()

                Text(sub.assessmentType.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(sub.assessmentType.badgeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(sub.assessmentType.badgeColor.opacity(0.16)))
            }

            // Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Сдано работ: \(completedTasksCount)/\(subjectTasks.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))

                    Spacer()

                    Text("\(Int(progressRatio * 100))%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(sub.themeColor)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)
                        Capsule()
                            .fill(sub.themeColor)
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(progressRatio))), height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(sub.themeColor.opacity(0.25), lineWidth: 0.8)
                )
        )
    }

    // MARK: - Compact Attendance Pod (Лекции и Практики)
    private func attendancePod(sub: Subject) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("ПОСЕЩАЕМОСТЬ")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                Button {
                    showAttendanceEditor = true
                    HapticManager.shared.touchGlass()
                } label: {
                    Text("Настроить нормы")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.cyan.opacity(0.8))
                }
            }

            HStack(spacing: 10) {
                // Lectures Counter Card
                attendanceCard(
                    title: "Лекции",
                    attended: sub.lecturesAttended,
                    total: sub.lecturesTotal,
                    tint: .blue
                ) {
                    store.incrementLectures(for: sub.id)
                }

                // Practices Counter Card
                attendanceCard(
                    title: "Практики",
                    attended: sub.practicesAttended,
                    total: sub.practicesTotal,
                    tint: .green
                ) {
                    store.incrementPractices(for: sub.id)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.8)
                )
        )
    }

    private func attendanceCard(title: String, attended: Int, total: Int, tint: Color, onIncrement: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Text("\(attended)/\(total)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(tint)
            }

            Button(action: onIncrement) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Посетил")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(tint.opacity(0.35))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(tint.opacity(0.6), lineWidth: 0.8))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
        )
    }

    // MARK: - Session Mini Card
    private func sessionMiniCard(sub: Subject) -> some View {
        let isExam = sub.assessmentType == .exam || sub.assessmentType == .diffTest

        return HStack(spacing: 12) {
            // Admission Checkbox
            Button {
                store.toggleAdmission(for: sub.id)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: sub.isAdmittedToExam ? "checkmark.shield.fill" : "shield")
                    Text(sub.isAdmittedToExam ? "Допуск есть" : "Без допуска")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundColor(sub.isAdmittedToExam ? .green : .orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Capsule().fill(sub.isAdmittedToExam ? Color.green.opacity(0.12) : Color.orange.opacity(0.12)))
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // Inline Grade
            if isExam {
                HStack(spacing: 4) {
                    ForEach([2, 3, 4, 5], id: \.self) { gradeVal in
                        let isSelected = sessionItem?.grade?.rawValue == gradeVal
                        Button {
                            var item = sessionItem ?? SessionItem(subjectId: sub.id)
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
                                        .fill(isSelected ? (gradeVal == 5 ? Color.green : (gradeVal == 4 ? Color.blue : (gradeVal == 3 ? Color.orange : Color.red))) : Color.white.opacity(0.06))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            } else {
                let isPassed = sessionItem?.testResult == .passed
                Button {
                    var item = sessionItem ?? SessionItem(subjectId: sub.id)
                    item.testResult = isPassed ? .failed : .passed
                    store.updateSessionItem(item)
                    HapticManager.shared.touchGlass()
                } label: {
                    Text(isPassed ? "Сдал" : "Не сдал")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(isPassed ? .green : .white.opacity(0.5))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(isPassed ? Color.green.opacity(0.18) : Color.white.opacity(0.06)))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.white.opacity(0.07), lineWidth: 0.8))
        )
    }

    // MARK: - Tasks & Practices Section
    private func tasksSection(sub: Subject) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ПРАКТИКИ И ЗАДАНИЯ (\(subjectTasks.count))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                Button {
                    store.generateBatchTasks(
                        subjectId: sub.id,
                        category: .lab,
                        count: 4,
                        prefix: "Лабораторная",
                        priority: .medium
                    )
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "sparkles")
                        Text("+ 4 лабы")
                    }
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.cyan.opacity(0.85))
                }
            }

            if subjectTasks.isEmpty {
                VStack(spacing: 6) {
                    Text("Заданий по дисциплине пока нет")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Text("Нажмите «+» вверху для добавления работы или сгенерируйте пачку лаб.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .padding(18)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))
            } else {
                VStack(spacing: 8) {
                    ForEach(subjectTasks) { task in
                        detailedTaskRow(task: task)
                    }
                }
            }
        }
    }

    // MARK: - Detailed Task Row with Inline Subtasks
    private func detailedTaskRow(task: StudyTask) -> some View {
        let isExpanded = expandedTaskIds.contains(task.id) || !task.subtasks.isEmpty

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                // Checkbox
                Button {
                    store.toggleTaskCompletion(task)
                } label: {
                    Image(systemName: task.status.isFinished ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundColor(task.status.isFinished ? .green : .white.opacity(0.35))
                }
                .buttonStyle(PlainButtonStyle())

                // Title & Subtitle
                Button {
                    selectedTaskForEdit = task
                    HapticManager.shared.touchGlass()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.system(size: 14, weight: task.status.isFinished ? .regular : .semibold, design: .rounded))
                            .foregroundColor(task.status.isFinished ? .white.opacity(0.4) : .white)
                            .strikethrough(task.status.isFinished, color: .white.opacity(0.35))
                            .lineLimit(1)

                        if !task.taskDescription.isEmpty {
                            Text(task.taskDescription)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                // Priority Indicator
                Circle()
                    .fill(task.priority.color)
                    .frame(width: 6, height: 6)

                // Date
                if let due = task.dueDate {
                    Text(formatCompactDate(due))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(due < Date() && !task.status.isFinished ? .red : .white.opacity(0.4))
                }
            }

            // Inline Subtask checklist
            if !task.subtasks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Divider().background(Color.white.opacity(0.06))

                    ForEach(task.subtasks) { subtask in
                        Button {
                            store.toggleSubtask(taskId: task.id, subtaskId: subtask.id)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 13))
                                    .foregroundColor(subtask.isCompleted ? .green : .white.opacity(0.3))

                                Text(subtask.title)
                                    .font(.system(size: 12))
                                    .foregroundColor(subtask.isCompleted ? .white.opacity(0.35) : .white.opacity(0.8))
                                    .strikethrough(subtask.isCompleted)

                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 1)
                    }
                }
                .padding(.leading, 28)
                .padding(.top, 2)
            }
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.8)
                )
        )
    }

    private func formatCompactDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "dd.MM"
        return df.string(from: date)
    }
}

// MARK: - Attendance Edit Sheet (Modal for setting total counts)
struct AttendanceEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: DataStore
    public var subject: Subject

    @State private var lecturesAttended: Int
    @State private var lecturesTotal: Int
    @State private var practicesAttended: Int
    @State private var practicesTotal: Int

    init(store: DataStore, subject: Subject) {
        self.store = store
        self.subject = subject
        self._lecturesAttended = State(initialValue: subject.lecturesAttended)
        self._lecturesTotal = State(initialValue: subject.lecturesTotal)
        self._practicesAttended = State(initialValue: subject.practicesAttended)
        self._practicesTotal = State(initialValue: subject.practicesTotal)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Лекции") {
                    Stepper("Посещено: \(lecturesAttended)", value: $lecturesAttended, in: 0...lecturesTotal)
                    Stepper("Всего лекций в плане: \(lecturesTotal)", value: $lecturesTotal, in: 1...100)
                }

                Section("Практики и семинары") {
                    Stepper("Посещено: \(practicesAttended)", value: $practicesAttended, in: 0...practicesTotal)
                    Stepper("Всего практик в плане: \(practicesTotal)", value: $practicesTotal, in: 1...100)
                }
            }
            .navigationTitle("Нормы посещаемости")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        store.updateAttendance(
                            for: subject.id,
                            lecturesAttended: lecturesAttended,
                            lecturesTotal: lecturesTotal,
                            practicesAttended: practicesAttended,
                            practicesTotal: practicesTotal
                        )
                        HapticManager.shared.notifySuccess()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}
