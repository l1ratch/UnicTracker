import Foundation

// MARK: - Archived Semester Summary
public struct ArchivedSemesterSummary: Codable, Equatable {
    public var completedTasksCount: Int
    public var totalTasksCount: Int
    public var archiveNote: String

    public init(
        completedTasksCount: Int = 0,
        totalTasksCount: Int = 0,
        archiveNote: String = ""
    ) {
        self.completedTasksCount = completedTasksCount
        self.totalTasksCount = totalTasksCount
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
        self.isArchived = isArchived
        self.archivedAt = archivedAt
        self.archivedSummary = archivedSummary
    }

    public var daysRemainingToEnd: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return max(0, components.day ?? 0)
    }
}
