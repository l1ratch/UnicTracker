import SwiftUI

public struct TaskEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: DataStore

    @State private var task: StudyTask
    @State private var isNewTask: Bool
    @State private var newSubtaskTitle: String = ""

    public init(store: DataStore, taskToEdit: StudyTask? = nil, defaultSubjectId: UUID? = nil) {
        self.store = store
        if let existing = taskToEdit {
            self._task = State(initialValue: existing)
            self._isNewTask = State(initialValue: false)
        } else {
            let initialSubId = defaultSubjectId ?? store.activeSubjects.first?.id ?? UUID()
            self._task = State(initialValue: StudyTask(
                subjectId: initialSubId,
                title: "",
                category: .lab,
                priority: .medium
            ))
            self._isNewTask = State(initialValue: true)
        }
    }

    public var body: some View {
        NavigationView {
            ZStack {
                MeshGradientBackground(store: store)

                ScrollView {
                    VStack(spacing: 20) {
                        // Title & Description Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ОСНОВНАЯ ИНФОРМАЦИЯ")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))

                            TextField("Название (напр. Лабораторная №1)", text: $task.title)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))

                            TextField("Описание / ссылка на методичку...", text: $task.taskDescription, axis: .vertical)
                                .lineLimit(3...5)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)

                        // Subject & Category Picker Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ДИСЦИПЛИНА И ТИП РАБОТЫ")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))

                            // Subject Picker
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Дисциплина")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.7))

                                Picker("Предмет", selection: $task.subjectId) {
                                    ForEach(store.activeSubjects) { sub in
                                        Text(sub.name).tag(sub.id)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .accentColor(.cyan)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            }

                            // Category Picker
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Тип задания")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.7))

                                Picker("Категория", selection: $task.category) {
                                    ForEach(TaskCategory.allCases) { cat in
                                        Label(cat.rawValue, systemImage: cat.systemIcon).tag(cat)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .accentColor(.cyan)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            }
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)

                        // Priority & Deadline Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ПРИОРИТЕТ И СРОК")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))

                            HStack(spacing: 8) {
                                ForEach(TaskPriority.allCases) { prio in
                                    let isSelected = task.priority == prio
                                    Button {
                                        task.priority = prio
                                        HapticManager.shared.touchGlass()
                                    } label: {
                                        Text(prio.rawValue)
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundColor(isSelected ? .white : prio.color)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(isSelected ? prio.color.opacity(0.4) : Color.white.opacity(0.06))
                                                    .overlay(Capsule().strokeBorder(prio.color.opacity(isSelected ? 0.8 : 0.3), lineWidth: 1))
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }

                            Divider().background(Color.white.opacity(0.1))

                            Toggle("Установить дедлайн", isOn: Binding(
                                get: { task.dueDate != nil },
                                set: { if $0 { task.dueDate = Date() } else { task.dueDate = nil } }
                            ))
                            .foregroundColor(.white)

                            if let due = task.dueDate {
                                DatePicker("Срок сдачи", selection: Binding(
                                    get: { due },
                                    set: { task.dueDate = $0 }
                                ), displayedComponents: [.date, .hourAndMinute])
                                .foregroundColor(.white)
                            }
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)

                        // Subtasks Template Builder
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ЭТАПЫ / ПОДЗАДАЧИ")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))

                            ForEach(task.subtasks.indices, id: \.self) { idx in
                                HStack {
                                    Image(systemName: "circle")
                                        .foregroundColor(.white.opacity(0.4))
                                    Text(task.subtasks[idx].title)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Button {
                                        task.subtasks.remove(at: idx)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red.opacity(0.7))
                                    }
                                }
                                .padding(.vertical, 4)
                            }

                            HStack {
                                TextField("Добавить этап...", text: $newSubtaskTitle)
                                    .foregroundColor(.white)
                                Button {
                                    guard !newSubtaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                    task.subtasks.append(Subtask(title: newSubtaskTitle.trimmingCharacters(in: .whitespaces)))
                                    newSubtaskTitle = ""
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.cyan)
                                }
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle(isNewTask ? "Новое задание" : "Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        if !task.title.trimmingCharacters(in: .whitespaces).isEmpty {
                            store.saveTask(task)
                            HapticManager.shared.notifySuccess()
                            dismiss()
                        }
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(task.title.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.3) : .cyan)
                    .disabled(task.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
