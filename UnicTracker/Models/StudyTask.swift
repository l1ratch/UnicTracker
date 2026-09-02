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

    enum CodingKeys: String, CodingKey {
        case id, subjectId, title, taskDescription, category, priority, status, subtasks, dueDate, pointsEarned, maxPoints, createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.subjectId = try container.decodeIfPresent(UUID.self, forKey: .subjectId) ?? UUID()
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.taskDescription = try container.decodeIfPresent(String.self, forKey: .taskDescription) ?? ""
        self.category = try container.decodeIfPresent(TaskCategory.self, forKey: .category) ?? .lab
        self.priority = try container.decodeIfPresent(TaskPriority.self, forKey: .priority) ?? .medium
        self.status = try container.decodeIfPresent(TaskStatus.self, forKey: .status) ?? .pending
        self.subtasks = try container.decodeIfPresent([Subtask].self, forKey: .subtasks) ?? []
        self.dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        self.pointsEarned = try container.decodeIfPresent(Double.self, forKey: .pointsEarned)
        self.maxPoints = try container.decodeIfPresent(Double.self, forKey: .maxPoints)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(subjectId, forKey: .subjectId)
        try container.encode(title, forKey: .title)
        try container.encode(taskDescription, forKey: .taskDescription)
        try container.encode(category, forKey: .category)
        try container.encode(priority, forKey: .priority)
        try container.encode(status, forKey: .status)
        try container.encode(subtasks, forKey: .subtasks)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encodeIfPresent(pointsEarned, forKey: .pointsEarned)
        try container.encodeIfPresent(maxPoints, forKey: .maxPoints)
        try container.encode(createdAt, forKey: .createdAt)
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
