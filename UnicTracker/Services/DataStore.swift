import SwiftUI
import Combine

@MainActor
public final class DataStore: ObservableObject {
    // MARK: - Published State
    @Published public var semesters: [Semester] = []
    @Published public var subjects: [Subject] = []
    @Published public var tasks: [StudyTask] = []
    @Published public var sessionItems: [SessionItem] = []
    @Published public var theme: AppThemeSettings = AppThemeSettings()

    // MARK: - Filter and UI State
    @Published public var selectedSubjectFilter: UUID? = nil
    @Published public var searchQuery: String = ""
    @Published public var selectedPriorityFilter: TaskPriority? = nil
    @Published public var selectedStatusTab: TaskFilterTab = .all

    public enum TaskFilterTab: String, CaseIterable, Identifiable {
        case all = "Все"
        case active = "В работе"
        case completed = "Сдано"
        case urgent = "Срочные"

        public var id: String { rawValue }
    }

    private let storage = StorageService.shared

    public init() {
        loadFromStorage()
    }

    // MARK: - Computed Helpers for Active Semester
    public var activeSemester: Semester? {
        semesters.first(where: { !$0.isArchived })
    }

    public var archivedSemesters: [Semester] {
        semesters.filter { $0.isArchived }.sorted { ($0.archivedAt ?? Date()) > ($1.archivedAt ?? Date()) }
    }

    public var activeSubjects: [Subject] {
        guard let activeSem = activeSemester else { return [] }
        return subjects.filter { $0.semesterId == activeSem.id }
    }

    public var activeTasks: [StudyTask] {
        let activeSubjectIds = Set(activeSubjects.map { $0.id })
        return tasks.filter { activeSubjectIds.contains($0.subjectId) }
    }

    public var activeSessionItems: [SessionItem] {
        let activeSubjectIds = Set(activeSubjects.map { $0.id })
        return sessionItems.filter { activeSubjectIds.contains($0.subjectId) }
    }

    // MARK: - Statistics Calculations
    public var overallProgressPercentage: Int {
        let currentTasks = activeTasks
        guard !currentTasks.isEmpty else { return 0 }
        let totalRatio = currentTasks.reduce(0.0) { $0 + $1.completionRatio }
        return Int((totalRatio / Double(currentTasks.count)) * 100)
    }

    public var criticalCount: Int {
        activeTasks.filter { $0.priority == .critical && !$0.status.isFinished }.count
    }

    public var highCount: Int {
        activeTasks.filter { $0.priority == .high && !$0.status.isFinished }.count
    }

    public var mediumCount: Int {
        activeTasks.filter { $0.priority == .medium && !$0.status.isFinished }.count
    }

    public var lowCount: Int {
        activeTasks.filter { $0.priority == .low && !$0.status.isFinished }.count
    }

    public var completedTasksCount: Int {
        activeTasks.filter { $0.status.isFinished }.count
    }

    public var totalTasksCount: Int {
        activeTasks.count
    }

    // MARK: - Filtered Tasks for Main List
    public var filteredTasks: [StudyTask] {
        var result = activeTasks

        if let subjectFilter = selectedSubjectFilter {
            result = result.filter { $0.subjectId == subjectFilter }
        }

        if let priority = selectedPriorityFilter {
            result = result.filter { $0.priority == priority }
        }

        switch selectedStatusTab {
        case .all:
            break
        case .active:
            result = result.filter { !$0.status.isFinished }
        case .completed:
            result = result.filter { $0.status.isFinished }
        case .urgent:
            result = result.filter { ($0.priority == .critical || $0.priority == .high) && !$0.status.isFinished }
        }

        if !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchQuery.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(q) ||
                $0.taskDescription.lowercased().contains(q) ||
                (getSubject(for: $0.subjectId)?.name.lowercased().contains(q) ?? false)
            }
        }

        return result.sorted {
            if $0.status.isFinished != $1.status.isFinished {
                return !$0.status.isFinished && $1.status.isFinished
            }
            if $0.priority.sortOrder != $1.priority.sortOrder {
                return $0.priority.sortOrder < $1.priority.sortOrder
            }
            if let d0 = $0.dueDate, let d1 = $1.dueDate {
                return d0 < d1
            }
            return $0.createdAt > $1.createdAt
        }
    }

    public func getSubject(for id: UUID) -> Subject? {
        subjects.first(where: { $0.id == id })
    }

    public func getSessionItem(for subjectId: UUID) -> SessionItem? {
        sessionItems.first(where: { $0.subjectId == subjectId })
    }

    // MARK: - Task Operations
    public func toggleTaskCompletion(_ task: StudyTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        HapticManager.shared.toggleTask()

        if tasks[index].status == .completed {
            tasks[index].status = .inProgress
            for subIndex in tasks[index].subtasks.indices {
                tasks[index].subtasks[subIndex].isCompleted = false
            }
        } else {
            tasks[index].status = .completed
            for subIndex in tasks[index].subtasks.indices {
                tasks[index].subtasks[subIndex].isCompleted = true
            }
        }
        persist()
    }

    public func toggleSubtask(taskId: UUID, subtaskId: UUID) {
        guard let taskIndex = tasks.firstIndex(where: { $0.id == taskId }),
              let subIndex = tasks[taskIndex].subtasks.firstIndex(where: { $0.id == subtaskId }) else { return }

        HapticManager.shared.touchGlass()
        tasks[taskIndex].subtasks[subIndex].isCompleted.toggle()

        let allCompleted = tasks[taskIndex].subtasks.allSatisfy { $0.isCompleted }
        let anyCompleted = tasks[taskIndex].subtasks.contains { $0.isCompleted }

        if allCompleted && !tasks[taskIndex].subtasks.isEmpty {
            tasks[taskIndex].status = .completed
        } else if anyCompleted {
            tasks[taskIndex].status = .inProgress
        }
        persist()
    }

    public func saveTask(_ task: StudyTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.insert(task, at: 0)
        }
        persist()
    }

    public func deleteTask(_ task: StudyTask) {
        tasks.removeAll(where: { $0.id == task.id })
        persist()
    }

    // MARK: - Subject Operations
    public func saveSubject(_ subject: Subject) {
        if let index = subjects.firstIndex(where: { $0.id == subject.id }) {
            subjects[index] = subject
        } else {
            subjects.append(subject)
            // Create matching session item if not present
            if !sessionItems.contains(where: { $0.subjectId == subject.id }) {
                let sessionItem = SessionItem(subjectId: subject.id)
                sessionItems.append(sessionItem)
            }
        }
        persist()
    }

    public func deleteSubject(_ subject: Subject) {
        tasks.removeAll(where: { $0.subjectId == subject.id })
        sessionItems.removeAll(where: { $0.subjectId == subject.id })
        subjects.removeAll(where: { $0.id == subject.id })
        persist()
    }

    // MARK: - Batch Task Generator
    public func generateBatchTasks(
        subjectId: UUID,
        category: TaskCategory,
        count: Int,
        prefix: String = "Лабораторная работа",
        priority: TaskPriority = .medium,
        subtasksTemplate: [String] = ["Выполнить код", "Оформить отчет", "Защитить у преподавателя"]
    ) {
        for i in 1...count {
            let subtasks = subtasksTemplate.map { Subtask(title: $0) }
            let newTask = StudyTask(
                subjectId: subjectId,
                title: "\(prefix) №\(i)",
                taskDescription: "Задание по дисциплине \(getSubject(for: subjectId)?.name ?? "")",
                category: category,
                priority: priority,
                status: .pending,
                subtasks: subtasks
            )
            tasks.append(newTask)
        }
        HapticManager.shared.notifySuccess()
        persist()
    }

    // MARK: - Session Operations
    public func updateSessionItem(_ item: SessionItem) {
        if let index = sessionItems.firstIndex(where: { $0.id == item.id }) {
            sessionItems[index] = item
        } else {
            sessionItems.append(item)
        }
        persist()
    }

    public func toggleAdmission(for subjectId: UUID) {
        guard let index = subjects.firstIndex(where: { $0.id == subjectId }) else { return }
        subjects[index].isAdmittedToExam.toggle()
        HapticManager.shared.touchGlass()
        persist()
    }

    // MARK: - Attendance Operations
    public func incrementLectures(for subjectId: UUID) {
        guard let index = subjects.firstIndex(where: { $0.id == subjectId }) else { return }
        if subjects[index].lecturesAttended < subjects[index].lecturesTotal {
            subjects[index].lecturesAttended += 1
        } else {
            subjects[index].lecturesAttended = 0
        }
        HapticManager.shared.touchGlass()
        persist()
    }

    public func incrementPractices(for subjectId: UUID) {
        guard let index = subjects.firstIndex(where: { $0.id == subjectId }) else { return }
        if subjects[index].practicesAttended < subjects[index].practicesTotal {
            subjects[index].practicesAttended += 1
        } else {
            subjects[index].practicesAttended = 0
        }
        HapticManager.shared.touchGlass()
        persist()
    }

    public func updateAttendance(for subjectId: UUID, lecturesAttended: Int, lecturesTotal: Int, practicesAttended: Int, practicesTotal: Int) {
        guard let index = subjects.firstIndex(where: { $0.id == subjectId }) else { return }
        subjects[index].lecturesAttended = max(0, lecturesAttended)
        subjects[index].lecturesTotal = max(1, lecturesTotal)
        subjects[index].practicesAttended = max(0, practicesAttended)
        subjects[index].practicesTotal = max(1, practicesTotal)
        persist()
    }

    // MARK: - Semester Lifecycle & Archiving
    public func createSemester(title: String, course: Int, semesterNumber: Int, startDate: Date, endDate: Date, sessionStart: Date?) {
        let newSem = Semester(
            title: title,
            academicYear: "\(Calendar.current.component(.year, from: startDate))/\(Calendar.current.component(.year, from: startDate) + 1)",
            courseNumber: course,
            semesterNumber: semesterNumber,
            startDate: startDate,
            endDate: endDate,
            sessionStartDate: sessionStart,
            sessionEndDate: endDate,
            isArchived: false
        )
        semesters.append(newSem)
        persist()
    }

    public func finishAndArchiveActiveSemester(notes: String = "") {
        guard let current = activeSemester,
              let index = semesters.firstIndex(where: { $0.id == current.id }) else { return }

        // Compute summary
        let activeSubs = activeSubjects
        let activeSubIds = Set(activeSubs.map { $0.id })
        let currentTasks = tasks.filter { activeSubIds.contains($0.subjectId) }
        let currentSession = sessionItems.filter { activeSubIds.contains($0.subjectId) }

        let completedTasks = currentTasks.filter { $0.status.isFinished }.count
        let exams = activeSubs.filter { $0.assessmentType == .exam }
        let tests = activeSubs.filter { $0.assessmentType == .test || $0.assessmentType == .diffTest }

        var passedExams = 0
        var totalGradeSum = 0
        var gradedCount = 0

        for exam in exams {
            if let item = currentSession.first(where: { $0.subjectId == exam.id }), let g = item.grade {
                if g != .unsatisfactory {
                    passedExams += 1
                }
                totalGradeSum += g.rawValue
                gradedCount += 1
            }
        }

        var passedTests = 0
        for test in tests {
            if let item = currentSession.first(where: { $0.subjectId == test.id }) {
                if item.testResult == .passed {
                    passedTests += 1
                }
            }
        }

        let avgGrade = gradedCount > 0 ? (Double(totalGradeSum) / Double(gradedCount)) : nil

        let summary = ArchivedSemesterSummary(
            completedTasksCount: completedTasks,
            totalTasksCount: currentTasks.count,
            passedExamsCount: passedExams,
            totalExamsCount: exams.count,
            passedTestsCount: passedTests,
            totalTestsCount: tests.count,
            averageGrade: avgGrade,
            archiveNote: notes
        )

        semesters[index].isArchived = true
        semesters[index].archivedAt = Date()
        semesters[index].archivedSummary = summary

        HapticManager.shared.notifySuccess()
        persist()
    }

    // MARK: - Persistence IO
    public func persist() {
        let backup = AppBackupData(
            semesters: semesters,
            subjects: subjects,
            tasks: tasks,
            sessionItems: sessionItems,
            themeSettings: theme
        )
        try? storage.save(data: backup)
    }

    public func loadFromStorage() {
        if let data = storage.load() {
            self.semesters = data.semesters
            self.subjects = data.subjects
            self.tasks = data.tasks
            self.sessionItems = data.sessionItems
            self.theme = data.themeSettings
        }
    }

    public func resetAll() {
        storage.clearAll()
        self.semesters = []
        self.subjects = []
        self.tasks = []
        self.sessionItems = []
        self.theme = AppThemeSettings()
        HapticManager.shared.notifyWarning()
    }

    public func applyImportedData(_ data: AppBackupData) {
        self.semesters = data.semesters
        self.subjects = data.subjects
        self.tasks = data.tasks
        self.sessionItems = data.sessionItems
        self.theme = data.themeSettings
        persist()
        HapticManager.shared.notifySuccess()
    }

    // MARK: - Load Demo University Data
    public func loadSampleData() {
        let semId = UUID()
        let now = Date()
        let endSem = Calendar.current.date(byAdding: .month, value: 4, to: now) ?? now
        let sessionStart = Calendar.current.date(byAdding: .month, value: 3, to: now) ?? now

        let sem = Semester(
            id: semId,
            title: "3 Курс • Осенний семестр",
            academicYear: "2026/2027",
            courseNumber: 3,
            semesterNumber: 5,
            startDate: now,
            endDate: endSem,
            sessionStartDate: sessionStart,
            sessionEndDate: endSem,
            isArchived: false
        )

        let sub1 = Subject(
            semesterId: semId,
            name: "Операционные системы",
            shortCode: "ОС",
            iconName: "cpu.fill",
            colorHex: SubjectColorOption.cyan.rawValue,
            teacherName: "Иванов А.С.",
            roomOrLink: "Ауд. 402 / Zoom",
            assessmentType: .exam,
            minPointsForAdmission: 60.0,
            isAdmittedToExam: true
        )

        let sub2 = Subject(
            semesterId: semId,
            name: "Базы данных и SQL",
            shortCode: "БД",
            iconName: "cylinder.split.1x2.fill",
            colorHex: SubjectColorOption.purple.rawValue,
            teacherName: "Петрова Е.В.",
            roomOrLink: "Ауд. 310",
            assessmentType: .diffTest,
            minPointsForAdmission: 50.0,
            isAdmittedToExam: false
        )

        let sub3 = Subject(
            semesterId: semId,
            name: "Архитектура ЭВМ",
            shortCode: "АЭВМ",
            iconName: "memorychip.fill",
            colorHex: SubjectColorOption.emerald.rawValue,
            teacherName: "Сидоров К.М.",
            roomOrLink: "Лаб. 104",
            assessmentType: .exam,
            minPointsForAdmission: 55.0,
            isAdmittedToExam: false
        )

        let sampleSubjects = [sub1, sub2, sub3]

        var sampleTasks: [StudyTask] = []
        // Labs for OS
        sampleTasks.append(StudyTask(
            subjectId: sub1.id,
            title: "Лабораторная №1: Процессы и потоки в UNIX",
            taskDescription: "Изучение fork(), exec(), pthread. Написание многопоточного сервера.",
            category: .lab,
            priority: .critical,
            status: .inProgress,
            subtasks: [
                Subtask(title: "Написать fork и обработку сигналов", isCompleted: true),
                Subtask(title: "Реализовать мьютексы pthread_mutex", isCompleted: false),
                Subtask(title: "Оформить титульный лист и отчет", isCompleted: false)
            ],
            dueDate: Calendar.current.date(byAdding: .day, value: 5, to: now)
        ))

        sampleTasks.append(StudyTask(
            subjectId: sub1.id,
            title: "Лабораторная №2: Управление памятью и mmap",
            taskDescription: "Виртуальная память, page faults, работа с системными вызовами mmap.",
            category: .lab,
            priority: .high,
            status: .pending,
            subtasks: [
                Subtask(title: "Реализовать кастомный аллокатор", isCompleted: false),
                Subtask(title: "Защитить на паре", isCompleted: false)
            ],
            dueDate: Calendar.current.date(byAdding: .day, value: 14, to: now)
        ))

        // Tasks for DB
        sampleTasks.append(StudyTask(
            subjectId: sub2.id,
            title: "Практика №1: Проектирование схемы БД (3НФ)",
            taskDescription: "ER-диаграмма и нормализация отношений до 3НФ и BCNF.",
            category: .practice,
            priority: .medium,
            status: .completed,
            subtasks: [
                Subtask(title: "Собрать требования предметной области", isCompleted: true),
                Subtask(title: "Построить схему в dbdiagram.io", isCompleted: true)
            ]
        ))

        sampleTasks.append(StudyTask(
            subjectId: sub2.id,
            title: "Курсовой проект: Веб-система с PostgreSQL",
            taskDescription: "Бэкенд, сложные агрегационные запросы, триггеры и транзакции.",
            category: .termProject,
            priority: .critical,
            status: .inProgress,
            subtasks: [
                Subtask(title: "Схема данных и миграции", isCompleted: true),
                Subtask(title: "Индексы и EXPLAIN ANALYZE", isCompleted: false),
                Subtask(title: "Пояснительная записка", isCompleted: false)
            ],
            dueDate: Calendar.current.date(byAdding: .day, value: 25, to: now)
        ))

        // Session items
        let session1 = SessionItem(
            subjectId: sub1.id,
            examDate: Calendar.current.date(byAdding: .day, value: 70, to: now),
            grade: nil,
            testResult: .pending,
            ticketsTotal: 30,
            ticketsLearned: 12
        )

        let session2 = SessionItem(
            subjectId: sub2.id,
            examDate: Calendar.current.date(byAdding: .day, value: 65, to: now),
            grade: nil,
            testResult: .pending,
            ticketsTotal: 25,
            ticketsLearned: 8
        )

        let session3 = SessionItem(
            subjectId: sub3.id,
            examDate: Calendar.current.date(byAdding: .day, value: 75, to: now),
            grade: nil,
            testResult: .pending,
            ticketsTotal: 20,
            ticketsLearned: 3
        )

        self.semesters = [sem]
        self.subjects = sampleSubjects
        self.tasks = sampleTasks
        self.sessionItems = [session1, session2, session3]
        persist()
        HapticManager.shared.notifySuccess()
    }
}
