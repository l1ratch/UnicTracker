import SwiftUI

public struct TaskRowView: View {
    @ObservedObject var store: DataStore
    public var task: StudyTask
    public var onOpenDetail: () -> Void

    @State private var isExpanded: Bool = false

    public init(store: DataStore, task: StudyTask, onOpenDetail: @escaping () -> Void) {
        self.store = store
        self.task = task
        self.onOpenDetail = onOpenDetail
    }

    private var subject: Subject? {
        store.getSubject(for: task.subjectId)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: Subject Tag + Priority + Category Icon
            HStack(alignment: .center, spacing: 8) {
                if let sub = subject {
                    HStack(spacing: 5) {
                        Image(systemName: sub.iconName)
                            .font(.system(size: 11, weight: .bold))
                        Text(sub.shortCode)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(sub.themeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(sub.themeColor.opacity(0.15))
                            .overlay(Capsule().strokeBorder(sub.themeColor.opacity(0.3), lineWidth: 0.8))
                    )
                }

                PriorityBadge(priority: task.priority, compact: false)

                Spacer()

                // Due date countdown if present
                if let due = task.dueDate {
                    HStack(spacing: 3) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 11))
                        Text(dueDateString(due))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(isOverdue(due) ? Color.red : Color.white.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(Color.white.opacity(0.06))
                    )
                }
            }

            // Main row: Checkbox + Title + Arrow
            HStack(alignment: .top, spacing: 12) {
                // Liquid Checkbox Button
                Button {
                    store.toggleTaskCompletion(task)
                } label: {
                    ZStack {
                        Circle()
                            .fill(task.status.isFinished ? Color.green : Color.white.opacity(0.08))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        task.status.isFinished ? Color.green.opacity(0.9) : Color.white.opacity(0.3),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: task.status.isFinished ? Color.green.opacity(0.6) : Color.clear, radius: 6)

                        if task.status.isFinished {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(.black)
                        } else if task.completionRatio > 0 {
                            Circle()
                                .trim(from: 0, to: CGFloat(task.completionRatio))
                                .stroke(Color.cyan, lineWidth: 2.5)
                                .frame(width: 20, height: 20)
                                .rotationEffect(.degrees(-90))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // Task Title & Subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(task.status.isFinished ? .white.opacity(0.45) : .white)
                        .strikethrough(task.status.isFinished, color: .white.opacity(0.4))
                        .multilineTextAlignment(.leading)

                    if !task.taskDescription.isEmpty {
                        Text(task.taskDescription)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Open Detail Button
                Button(action: onOpenDetail) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(6)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Subtasks checklist preview (if any)
            if !task.subtasks.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Divider()
                        .background(Color.white.opacity(0.08))

                    HStack {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                isExpanded.toggle()
                            }
                            HapticManager.shared.touchGlass()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: isExpanded ? "chevron.down" : "chevron.forward")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Чеклист (\(task.subtasks.filter { $0.isCompleted }.count)/\(task.subtasks.count))")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.cyan.opacity(0.9))
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()

                        // Mini progress bar
                        ProgressView(value: task.completionRatio)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color.cyan))
                            .frame(width: 70)
                    }

                    if isExpanded {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(task.subtasks) { subtask in
                                Button {
                                    store.toggleSubtask(taskId: task.id, subtaskId: subtask.id)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 14))
                                            .foregroundColor(subtask.isCompleted ? .green : .white.opacity(0.4))

                                        Text(subtask.title)
                                            .font(.system(size: 13))
                                            .foregroundColor(subtask.isCompleted ? .white.opacity(0.4) : .white.opacity(0.85))
                                            .strikethrough(subtask.isCompleted)

                                        Spacer()
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.top, 4)
                        .padding(.leading, 4)
                    }
                }
            }
        }
        .padding(14)
        .liquidGlass(
            cornerRadius: 18,
            depth: store.theme.glassDepth,
            tint: subject?.themeColor,
            specular: true,
            glow: 0.3
        )
        .contentShape(Rectangle())
    }

    private func dueDateString(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Сегодня"
        } else if calendar.isDateInTomorrow(date) {
            return "Завтра"
        } else {
            let df = DateFormatter()
            df.dateFormat = "dd.MM"
            return df.string(from: date)
        }
    }

    private func isOverdue(_ date: Date) -> Bool {
        !task.status.isFinished && date < Date()
    }
}
