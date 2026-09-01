import SwiftUI

// MARK: - Task Priority (Liquid Visual Hierarchy)
public enum TaskPriority: String, CaseIterable, Identifiable, Codable {
    case critical = "Критичный"
    case high = "Высокий"
    case medium = "Средний"
    case low = "Низкий"

    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .critical: return Color(red: 1.0, green: 0.22, blue: 0.35)
        case .high: return Color(red: 1.0, green: 0.58, blue: 0.0)
        case .medium: return Color(red: 0.0, green: 0.8, blue: 0.95)
        case .low: return Color(red: 0.3, green: 0.85, blue: 0.4)
        }
    }

    public var iconName: String {
        switch self {
        case .critical: return "exclamationmark.3"
        case .high: return "exclamationmark.2"
        case .medium: return "exclamationmark"
        case .low: return "arrow.down"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}

// MARK: - Task Category Type
public enum TaskCategory: String, CaseIterable, Identifiable, Codable {
    case lab = "Лабораторная"
    case practice = "Практика"
    case homework = "Домашнее задание"
    case termProject = "Курсовая работа"
    case seminar = "Семинар / Доклад"
    case testPrep = "Подготовка к зачету"
    case custom = "Другое"

    public var id: String { rawValue }

    public var systemIcon: String {
        switch self {
        case .lab: return "flask.fill"
        case .practice: return "wrench.and.screwdriver.fill"
        case .homework: return "book.closed.fill"
        case .termProject: return "folder.fill.badge.gearshape"
        case .seminar: return "person.wave.2.fill"
        case .testPrep: return "checklist.checked"
        case .custom: return "pencil.and.outline"
        }
    }
}

// MARK: - Task Status
public enum TaskStatus: String, CaseIterable, Identifiable, Codable {
    case pending = "Не начато"
    case inProgress = "В процессе"
    case submitted = "На проверке"
    case completed = "Зачтено"
    case needsFix = "Требует доработки"

    public var id: String { rawValue }

    public var isFinished: Bool {
        self == .completed
    }

    public var statusColor: Color {
        switch self {
        case .pending: return Color.gray.opacity(0.8)
        case .inProgress: return Color.blue
        case .submitted: return Color.orange
        case .completed: return Color.green
        case .needsFix: return Color.red
        }
    }

    public var iconName: String {
        switch self {
        case .pending: return "circle"
        case .inProgress: return "hourglass"
        case .submitted: return "arrow.up.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .needsFix: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Subtask Item
public struct Subtask: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var isCompleted: Bool

    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

// MARK: - Main Study Task Model
public struct StudyTask: Identifiable, Codable, Equatable {
    public var id: UUID
    public var subjectId: UUID
    public var title: String
    public var taskDescription: String
    public var category: TaskCategory
    public var priority: TaskPriority
    public var status: TaskStatus
    public var subtasks: [Subtask]
    public var dueDate: Date?
    public var pointsEarned: Double?
    public var maxPoints: Double?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        subjectId: UUID,
        title: String,
        taskDescription: String = "",
        category: TaskCategory = .lab,
        priority: TaskPriority = .medium,
        status: TaskStatus = .pending,
        subtasks: [Subtask] = [],
        dueDate: Date? = nil,
        pointsEarned: Double? = nil,
        maxPoints: Double? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.subjectId = subjectId
        self.title = title
        self.taskDescription = taskDescription
        self.category = category
        self.priority = priority
        self.status = status
        self.subtasks = subtasks
        self.dueDate = dueDate
        self.pointsEarned = pointsEarned
        self.maxPoints = maxPoints
        self.createdAt = createdAt
    }

    public var completionRatio: Double {
        if status == .completed { return 1.0 }
        if subtasks.isEmpty {
            return status == .inProgress ? 0.5 : (status == .submitted ? 0.8 : 0.0)
        }
        let completedCount = subtasks.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(subtasks.count)
    }

    public var progressPercentage: Int {
        Int(completionRatio * 100)
    }
}
