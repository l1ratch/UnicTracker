import SwiftUI

// MARK: - Subject Importance Level (Уровень важности предмета)
public enum SubjectImportance: String, CaseIterable, Identifiable, Codable {
    case critical = "Критичный"
    case high = "Высокий"
    case medium = "Средний"
    case low = "Обычный"

    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .critical: return Color.red
        case .high: return Color.orange
        case .medium: return Color.yellow
        case .low: return Color.green
        }
    }

    public var order: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
}

// MARK: - Assessment Type (Форма итогового контроля)
public enum AssessmentType: String, CaseIterable, Identifiable, Codable {
    case exam = "Экзамен"
    case test = "Зачет"
    case diffTest = "Диф. зачет"
    case courseWork = "Курсовая"
    case credit = "Практика"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .exam: return "graduationcap.fill"
        case .test: return "checkmark.shield.fill"
        case .diffTest: return "star.shield.fill"
        case .courseWork: return "doc.text.image.fill"
        case .credit: return "medal.fill"
        }
    }

    public var badgeColor: Color {
        switch self {
        case .exam: return Color.purple
        case .test: return Color.blue
        case .diffTest: return Color.orange
        case .courseWork: return Color.pink
        case .credit: return Color.teal
        }
    }
}

// MARK: - Subject Color Palette
public enum SubjectColorOption: String, CaseIterable, Identifiable, Codable {
    case cyan = "#00E5FF"
    case purple = "#BF5AF2"
    case emerald = "#30D158"
    case sunsetOrange = "#FF9F0A"
    case electricBlue = "#0A84FF"
    case neonPink = "#FF375F"
    case royalIndigo = "#5E5CE6"
    case amberYellow = "#FFD60A"

    public var id: String { rawValue }

    public var color: Color {
        Color(hex: rawValue)
    }
}

// MARK: - Subject Model
public struct Subject: Identifiable, Codable, Equatable {
    public var id: UUID
    public var semesterId: UUID
    public var name: String
    public var shortCode: String
    public var iconName: String
    public var colorHex: String
    public var teacherName: String
    public var roomOrLink: String
    public var assessmentType: AssessmentType
    public var importance: SubjectImportance
    public var minPointsForAdmission: Double?
    public var isAdmittedToExam: Bool
    public var notes: String

    // Attendance counters (Посещаемость: лекции и практики)
    public var lecturesAttended: Int
    public var lecturesTotal: Int
    public var practicesAttended: Int
    public var practicesTotal: Int

    public init(
        id: UUID = UUID(),
        semesterId: UUID,
        name: String,
        shortCode: String = "",
        iconName: String = "book.fill",
        colorHex: String = SubjectColorOption.cyan.rawValue,
        teacherName: String = "",
        roomOrLink: String = "",
        assessmentType: AssessmentType = .exam,
        importance: SubjectImportance = .medium,
        minPointsForAdmission: Double? = 50.0,
        isAdmittedToExam: Bool = false,
        notes: String = "",
        lecturesAttended: Int = 0,
        lecturesTotal: Int = 16,
        practicesAttended: Int = 0,
        practicesTotal: Int = 16
    ) {
        self.id = id
        self.semesterId = semesterId
        self.name = name
        self.shortCode = shortCode.isEmpty ? String(name.prefix(4)).uppercased() : shortCode
        self.iconName = iconName
        self.colorHex = colorHex
        self.teacherName = teacherName
        self.roomOrLink = roomOrLink
        self.assessmentType = assessmentType
        self.importance = importance
        self.minPointsForAdmission = minPointsForAdmission
        self.isAdmittedToExam = isAdmittedToExam
        self.notes = notes
        self.lecturesAttended = lecturesAttended
        self.lecturesTotal = lecturesTotal
        self.practicesAttended = practicesAttended
        self.practicesTotal = practicesTotal
    }

    enum CodingKeys: String, CodingKey {
        case id, semesterId, name, shortCode, iconName, colorHex
        case teacherName, roomOrLink, assessmentType, importance
        case minPointsForAdmission, isAdmittedToExam, notes
        case lecturesAttended, lecturesTotal, practicesAttended, practicesTotal
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.semesterId = try container.decodeIfPresent(UUID.self, forKey: .semesterId) ?? UUID()
        let rawName = try container.decodeIfPresent(String.self, forKey: .name) ?? "Дисциплина"
        self.name = rawName
        let decodedShortCode = try container.decodeIfPresent(String.self, forKey: .shortCode) ?? ""
        self.shortCode = decodedShortCode.isEmpty ? String(rawName.prefix(4)).uppercased() : decodedShortCode
        self.iconName = try container.decodeIfPresent(String.self, forKey: .iconName) ?? "book.fill"
        self.colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex) ?? SubjectColorOption.cyan.rawValue
        self.teacherName = try container.decodeIfPresent(String.self, forKey: .teacherName) ?? ""
        self.roomOrLink = try container.decodeIfPresent(String.self, forKey: .roomOrLink) ?? ""
        self.assessmentType = try container.decodeIfPresent(AssessmentType.self, forKey: .assessmentType) ?? .exam
        self.importance = try container.decodeIfPresent(SubjectImportance.self, forKey: .importance) ?? .medium
        self.minPointsForAdmission = try container.decodeIfPresent(Double.self, forKey: .minPointsForAdmission)
        self.isAdmittedToExam = try container.decodeIfPresent(Bool.self, forKey: .isAdmittedToExam) ?? false
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.lecturesAttended = try container.decodeIfPresent(Int.self, forKey: .lecturesAttended) ?? 0
        self.lecturesTotal = try container.decodeIfPresent(Int.self, forKey: .lecturesTotal) ?? 16
        self.practicesAttended = try container.decodeIfPresent(Int.self, forKey: .practicesAttended) ?? 0
        self.practicesTotal = try container.decodeIfPresent(Int.self, forKey: .practicesTotal) ?? 16
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(semesterId, forKey: .semesterId)
        try container.encode(name, forKey: .name)
        try container.encode(shortCode, forKey: .shortCode)
        try container.encode(iconName, forKey: .iconName)
        try container.encode(colorHex, forKey: .colorHex)
        try container.encode(teacherName, forKey: .teacherName)
        try container.encode(roomOrLink, forKey: .roomOrLink)
        try container.encode(assessmentType, forKey: .assessmentType)
        try container.encode(importance, forKey: .importance)
        try container.encodeIfPresent(minPointsForAdmission, forKey: .minPointsForAdmission)
        try container.encode(isAdmittedToExam, forKey: .isAdmittedToExam)
        try container.encode(notes, forKey: .notes)
        try container.encode(lecturesAttended, forKey: .lecturesAttended)
        try container.encode(lecturesTotal, forKey: .lecturesTotal)
        try container.encode(practicesAttended, forKey: .practicesAttended)
        try container.encode(practicesTotal, forKey: .practicesTotal)
    }

    public var themeColor: Color {
        Color(hex: colorHex)
    }
}

// MARK: - Color Hex Helper Extension
public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 229, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        return "#00E5FF"
    }
}
