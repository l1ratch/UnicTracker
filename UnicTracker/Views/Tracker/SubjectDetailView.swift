import SwiftUI

public struct SubjectDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: DataStore
    public var subjectId: UUID

    @State private var showTaskCreateSheet: Bool = false
    @State private var showSubjectEditSheet: Bool = false
    @State private var selectedTaskForEdit: StudyTask? = nil
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
                        // MARK: - Subject Header Card (Short Code + Full Name + Importance + Edit)
                        subjectHeaderCard(sub: sub)

                        // MARK: - Compact Attendance Pod (Лекции и Практики)
                        attendancePod(sub: sub)

                        // MARK: - Tasks & Practices Checklist with Subtasks
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
        .navigationTitle(subject?.shortCode ?? "Дисциплина")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Edit Subject Button
                Button {
                    showSubjectEditSheet = true
                    HapticManager.shared.touchGlass()
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.8))
                }

                // Add Task Button
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
        .sheet(isPresented: $showSubjectEditSheet) {
            if let sub = subject {
                SubjectEditView(store: store, subjectToEdit: sub)
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

    // MARK: - Subject Header Card (Short Code, Full Name, Importance, Teacher)
    private func subjectHeaderCard(sub: Subject) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                // Prominent Short Code Tag
                Text(sub.shortCode)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(sub.themeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(sub.themeColor.opacity(0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(sub.themeColor.opacity(0.4), lineWidth: 1)
                            )
                    )

                VStack(alignment: .leading, spacing: 3) {
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

                // Importance Level Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(sub.importance.color)
                        .frame(width: 6, height: 6)

                    Text(sub.importance.rawValue)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(sub.importance.color)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(sub.importance.color.opacity(0.14))
                )
            }

            // Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Сдано практик: \(completedTasksCount)/\(subjectTasks.count)")
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

// MARK: - Attendance Edit Sheet Modal
public struct AttendanceEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: DataStore
    public var subject: Subject

    @State private var lecturesTotal: Int
    @State private var practicesTotal: Int

    public init(store: DataStore, subject: Subject) {
        self.store = store
        self.subject = subject
        self._lecturesTotal = State(initialValue: subject.lecturesTotal)
        self._practicesTotal = State(initialValue: subject.practicesTotal)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Нормы посещаемости") {
                    Stepper("Всего лекций в плане: \(lecturesTotal)", value: $lecturesTotal, in: 1...100)
                    Stepper("Всего практик в плане: \(practicesTotal)", value: $practicesTotal, in: 1...100)
                }
            }
            .navigationTitle("Настройка норм")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        var updated = subject
                        updated.lecturesTotal = lecturesTotal
                        updated.practicesTotal = practicesTotal
                        store.saveSubject(updated)
                        HapticManager.shared.notifySuccess()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                }
            }
        }
    }
}

