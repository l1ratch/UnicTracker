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

    enum CodingKeys: String, CodingKey {
        case id, title, academicYear, courseNumber, semesterNumber
        case startDate, endDate, isArchived, archivedAt, archivedSummary
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case sessionStartDate, sessionEndDate
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Семестр"
        self.academicYear = try container.decodeIfPresent(String.self, forKey: .academicYear) ?? "2026/2027"
        self.courseNumber = try container.decodeIfPresent(Int.self, forKey: .courseNumber) ?? 1
        self.semesterNumber = try container.decodeIfPresent(Int.self, forKey: .semesterNumber) ?? 1
        self.startDate = try container.decodeIfPresent(Date.self, forKey: .startDate) ?? Date()

        let legacyContainer = try? decoder.container(keyedBy: LegacyCodingKeys.self)
        let legacyEnd = try? legacyContainer?.decodeIfPresent(Date.self, forKey: .sessionEndDate)

        let cal = Calendar.current
        let defaultEnd = cal.date(byAdding: .month, value: 5, to: Date()) ?? Date()
        self.endDate = (try container.decodeIfPresent(Date.self, forKey: .endDate)) ?? legacyEnd ?? defaultEnd
        self.isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        self.archivedAt = try container.decodeIfPresent(Date.self, forKey: .archivedAt)
        self.archivedSummary = try container.decodeIfPresent(ArchivedSemesterSummary.self, forKey: .archivedSummary)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(academicYear, forKey: .academicYear)
        try container.encode(courseNumber, forKey: .courseNumber)
        try container.encode(semesterNumber, forKey: .semesterNumber)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(isArchived, forKey: .isArchived)
        try container.encodeIfPresent(archivedAt, forKey: .archivedAt)
        try container.encodeIfPresent(archivedSummary, forKey: .archivedSummary)
    }

    public var daysRemainingToEnd: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: endDate)
        return max(0, components.day ?? 0)
    }
}
