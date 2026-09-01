import Foundation

// MARK: - Root Backup & Persistence Schema
public struct AppBackupData: Codable {
    public var version: String = "2.0-liquid"
    public var exportedAt: Date = Date()
    public var semesters: [Semester]
    public var subjects: [Subject]
    public var tasks: [StudyTask]
    public var sessionItems: [SessionItem]
    public var themeSettings: AppThemeSettings

    public init(
        semesters: [Semester] = [],
        subjects: [Subject] = [],
        tasks: [StudyTask] = [],
        sessionItems: [SessionItem] = [],
        themeSettings: AppThemeSettings = AppThemeSettings()
    ) {
        self.semesters = semesters
        self.subjects = subjects
        self.tasks = tasks
        self.sessionItems = sessionItems
        self.themeSettings = themeSettings
    }
}

// MARK: - Local Persistence & Export Engine
public final class StorageService {
    public static let shared = StorageService()

    private let fileName = "unic_tracker_database.json"
    private let fileManager = FileManager.default

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var fileURL: URL {
        documentsDirectory.appendingPathComponent(fileName)
    }

    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Save Local
    public func save(data: AppBackupData) throws {
        let rawData = try jsonEncoder.encode(data)
        try rawData.write(to: fileURL, options: [.atomicWrite, .completeFileProtection])
    }

    // MARK: - Load Local
    public func load() -> AppBackupData? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: fileURL)
            return try jsonDecoder.decode(AppBackupData.self, data: data)
        } catch {
            print("StorageService: Error reading database: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Export Data to File URL for Share Sheet
    public func exportToFileURL(data: AppBackupData) -> URL? {
        do {
            let jsonData = try jsonEncoder.encode(data)
            let tempDir = fileManager.temporaryDirectory
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateStr = dateFormatter.string(from: Date())
            let exportURL = tempDir.appendingPathComponent("UnicTracker_Backup_\(dateStr).json")
            try jsonData.write(to: exportURL, options: .atomic)
            return exportURL
        } catch {
            print("StorageService: Export error: \(error)")
            return nil
        }
    }

    // MARK: - Import from JSON Data
    public func importFromJSON(data: Data) throws -> AppBackupData {
        return try jsonDecoder.decode(AppBackupData.self, data: data)
    }

    // MARK: - Clear All Local Files
    public func clearAll() {
        try? fileManager.removeItem(at: fileURL)
    }
}
