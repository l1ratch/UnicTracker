import SwiftUI

// MARK: - Exam Grade (Традиционная система РФ / 5-балльная)
public enum ExamGrade: Int, CaseIterable, Identifiable, Codable {
    case excellent = 5
    case good = 4
    case satisfactory = 3
    case unsatisfactory = 2

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .excellent: return "5 (Отлично)"
        case .good: return "4 (Хорошо)"
        case .satisfactory: return "3 (Удовлетворительно)"
        case .unsatisfactory: return "2 (Неуд)"
        }
    }

    public var shortTitle: String {
        "\(rawValue)"
    }

    public var color: Color {
        switch self {
        case .excellent: return Color.green
        case .good: return Color.blue
        case .satisfactory: return Color.orange
        case .unsatisfactory: return Color.red
        }
    }
}

// MARK: - Test Result (Зачет / Незачет)
public enum TestResult: String, CaseIterable, Identifiable, Codable {
    case passed = "Зачтено"
    case failed = "Не зачтено"
    case pending = "Не сдавалось"

    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .passed: return Color.green
        case .failed: return Color.red
        case .pending: return Color.gray
        }
    }

    public var iconName: String {
        switch self {
        case .passed: return "checkmark.seal.fill"
        case .failed: return "xmark.seal.fill"
        case .pending: return "clock.fill"
        }
    }
}

// MARK: - Session Item Model
public struct SessionItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var subjectId: UUID
    public var examDate: Date?
    public var grade: ExamGrade?
    public var testResult: TestResult
    public var scorePoints: Double?
    public var maxScorePoints: Double?
    public var ticketsTotal: Int
    public var ticketsLearned: Int
    public var isRetake: Bool
    public var notes: String

    public init(
        id: UUID = UUID(),
        subjectId: UUID,
        examDate: Date? = nil,
        grade: ExamGrade? = nil,
        testResult: TestResult = .pending,
        scorePoints: Double? = nil,
        maxScorePoints: Double? = 100.0,
        ticketsTotal: Int = 0,
        ticketsLearned: Int = 0,
        isRetake: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.subjectId = subjectId
        self.examDate = examDate
        self.grade = grade
        self.testResult = testResult
        self.scorePoints = scorePoints
        self.maxScorePoints = maxScorePoints
        self.ticketsTotal = ticketsTotal
        self.ticketsLearned = ticketsLearned
        self.isRetake = isRetake
        self.notes = notes
    }

    public var isCompleted: Bool {
        if grade != nil {
            return grade != .unsatisfactory
        }
        return testResult == .passed
    }

    public var ticketPreparationRatio: Double {
        guard ticketsTotal > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(ticketsLearned) / Double(ticketsTotal)))
    }
}
