import SwiftUI

public struct TaskDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: DataStore
    @State var task: StudyTask

    @State private var newSubtaskText: String = ""
    @State private var showDeleteConfirm: Bool = false
    @State private var showEditTaskSheet: Bool = false

    public init(store: DataStore, task: StudyTask) {
        self.store = store
        self._task = State(initialValue: task)
    }

    private var subject: Subject? {
        store.getSubject(for: task.subjectId)
    }

    public var body: some View {
        NavigationView {
            ZStack {
                MeshGradientBackground(store: store)

                ScrollView {
                    VStack(spacing: 20) {
                        // Header Card: Subject & Category
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                if let sub = subject {
                                    HStack(spacing: 6) {
                                        Image(systemName: sub.iconName)
                                        Text(sub.name)
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                    }
                                    .foregroundColor(sub.themeColor)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule().fill(sub.themeColor.opacity(0.15))
                                    )
                                }

                                Spacer()

                                PriorityBadge(priority: task.priority)
                            }

                            Text(task.title)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            if !task.taskDescription.isEmpty {
                                Text(task.taskDescription)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.75))
                            }
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth, tint: subject?.themeColor)

                        // Status Selector Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("СТАТУС ВЫПОЛНЕНИЯ")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(TaskStatus.allCases) { status in
                                        Button {
                                            task.status = status
                                            if status == .completed {
                                                for i in task.subtasks.indices {
                                                    task.subtasks[i].isCompleted = true
                                                }
                                            }
                                            store.saveTask(task)
                                            HapticManager.shared.selectionChanged()
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: status.iconName)
                                                Text(status.rawValue)
                                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            }
                                            .foregroundColor(task.status == status ? .white : .white.opacity(0.6))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(task.status == status ? status.statusColor.opacity(0.5) : Color.white.opacity(0.06))
                                                    .overlay(
                                                        Capsule().strokeBorder(
                                                            task.status == status ? status.statusColor : Color.white.opacity(0.12),
                                                            lineWidth: 1
                                                        )
                                                    )
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)

                        // Subtasks / Checklist Card
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("ЭТАПЫ И ПОДЗАДАЧИ")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.5))

                                Spacer()

                                Text("\(task.progressPercentage)%")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.cyan)
                            }

                            // Progress bar
                            ProgressView(value: task.completionRatio)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color.cyan))

                            // Subtask items list
                            VStack(spacing: 8) {
                                ForEach(task.subtasks) { subtask in
                                    HStack {
                                        Button {
                                            if let idx = task.subtasks.firstIndex(where: { $0.id == subtask.id }) {
                                                task.subtasks[idx].isCompleted.toggle()
                                                store.saveTask(task)
                                                HapticManager.shared.touchGlass()
                                            }
                                        } label: {
                                            HStack(spacing: 10) {
                                                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(subtask.isCompleted ? .green : .white.opacity(0.4))

                                                Text(subtask.title)
                                                    .font(.system(size: 15))
                                                    .foregroundColor(subtask.isCompleted ? .white.opacity(0.4) : .white)
                                                    .strikethrough(subtask.isCompleted)

                                                Spacer()
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        Button {
                                            task.subtasks.removeAll(where: { $0.id == subtask.id })
                                            store.saveTask(task)
                                            HapticManager.shared.touchGlass()
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 13))
                                                .foregroundColor(.red.opacity(0.6))
                                                .padding(4)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }

                            // Add new subtask row
                            HStack {
                                TextField("Добавить подзадачу...", text: $newSubtaskText)
                                    .foregroundColor(.white)
                                    .textFieldStyle(PlainTextFieldStyle())

                                Button {
                                    guard !newSubtaskText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                    task.subtasks.append(Subtask(title: newSubtaskText.trimmingCharacters(in: .whitespaces)))
                                    newSubtaskText = ""
                                    store.saveTask(task)
                                    HapticManager.shared.touchGlass()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.cyan)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.06))
                            )
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)

                        // Due Date & Info Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ДЕДЛАЙН И ИНФОРМАЦИЯ")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))

                            if let due = task.dueDate {
                                HStack {
                                    Label("Срок сдачи:", systemImage: "calendar")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.7))

                                    Spacer()

                                    Text(due.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }

                            if let teacher = subject?.teacherName, !teacher.isEmpty {
                                HStack {
                                    Label("Преподаватель:", systemImage: "person.crop.circle")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.7))

                                    Spacer()

                                    Text(teacher)
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }

                            if let room = subject?.roomOrLink, !room.isEmpty {
                                HStack {
                                    Label("Аудитория / Ссылка:", systemImage: "mappin.and.ellipse")
                                        .font(.system(size: 15))
                                        .foregroundColor(.white.opacity(0.7))

                                    Spacer()

                                    Text(room)
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)

                        // Delete Action
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Удалить задание")
                            }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(GlassButtonStyle(tint: Color.red.opacity(0.3), cornerRadius: 18))
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Детали задания")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showEditTaskSheet = true
                        HapticManager.shared.touchGlass()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                            Text("Править")
                        }
                        .foregroundColor(.cyan)
                        .font(.system(size: 15, weight: .semibold))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        store.saveTask(task)
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                    .font(.system(size: 16, weight: .bold))
                }
            }
            .sheet(isPresented: $showEditTaskSheet) {
                TaskEditView(store: store, taskToEdit: task, defaultSubjectId: task.subjectId)
            }
            .onChange(of: showEditTaskSheet) {
                if !showEditTaskSheet, let updated = store.tasks.first(where: { $0.id == task.id }) {
                    self.task = updated
                }
            }
            .alert("Удалить задание?", isPresented: $showDeleteConfirm) {
                Button("Удалить", role: .destructive) {
                    store.deleteTask(task)
                    dismiss()
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Это действие безвозвратно удалит выбранное задание и его подзадачи.")
            }
        }
    }
}
