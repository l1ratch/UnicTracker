import Foundation

// MARK: - Archived Semester Summary
public struct ArchivedSemesterSummary: Codable, Equatable {
    public var completedTasksCount: Int
    public var totalTasksCount: Int
    public var passedExamsCount: Int
    public var totalExamsCount: Int
    public var passedTestsCount: Int
    public var totalTestsCount: Int
    public var averageGrade: Double?
    public var archiveNote: String

    public init(
        completedTasksCount: Int = 0,
        totalTasksCount: Int = 0,
        passedExamsCount: Int = 0,
        totalExamsCount: Int = 0,
        passedTestsCount: Int = 0,
        totalTestsCount: Int = 0,
        averageGrade: Double? = nil,
        archiveNote: String = ""
    ) {
        self.completedTasksCount = completedTasksCount
        self.totalTasksCount = totalTasksCount
        self.passedExamsCount = passedExamsCount
        self.totalExamsCount = totalExamsCount
        self.passedTestsCount = passedTestsCount
        self.totalTestsCount = totalTestsCount
        self.averageGrade = averageGrade
        self.archiveNote = archiveNote
    }
}

// MARK: - Semester Model
public struct Semester: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var academicYear: String
    public var courseNumber: Int
    public var semesterNumber: Int
    public var startDate: Date
    public var endDate: Date
    public var sessionStartDate: Date?
    public var sessionEndDate: Date?
    public var isArchived: Bool
    public var archivedAt: Date?
    public var archivedSummary: ArchivedSemesterSummary?

    public init(
        id: UUID = UUID(),
        title: String,
        academicYear: String = "2026/2027",
        courseNumber: Int = 1,
        semesterNumber: Int = 1,
        startDate: Date = Date(),
        endDate: Date = Calendar.current.date(byAdding: .month, value: 5, to: Date()) ?? Date(),
        sessionStartDate: Date? = Calendar.current.date(byAdding: .month, value: 4, to: Date()),
        sessionEndDate: Date? = Calendar.current.date(byAdding: .month, value: 5, to: Date()),
        isArchived: Bool = false,
        archivedAt: Date? = nil,
        archivedSummary: ArchivedSemesterSummary? = nil
    ) {
        self.id = id
        self.title = title
        self.academicYear = academicYear
        self.courseNumber = courseNumber
        self.semesterNumber = semesterNumber
        self.startDate = startDate
        self.endDate = endDate
        self.sessionStartDate = sessionStartDate
        self.sessionEndDate = sessionEndDate
        self.isArchived = isArchived
        self.archivedAt = archivedAt
        self.archivedSummary = archivedSummary
    }

    public var daysRemainingToEnd: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return max(0, components.day ?? 0)
    }

    public var daysRemainingToSession: Int {
        guard let sessionStart = sessionStartDate else { return daysRemainingToEnd }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: sessionStart)
        return max(0, components.day ?? 0)
    }
}
