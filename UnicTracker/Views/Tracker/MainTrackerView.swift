import SwiftUI

public struct MainTrackerView: View {
    @ObservedObject var store: DataStore
    public var onOpenSettings: () -> Void

    @State private var showSubjectCreateSheet: Bool = false
    @State private var showTaskCreateSheet: Bool = false
    @State private var selectedSubjectForNewTask: UUID? = nil

    public init(store: DataStore, onOpenSettings: @escaping () -> Void) {
        self.store = store
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: store.theme.preset.backgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // MARK: - Top Summary Mini Bar
                    compactTopSummary

                    // MARK: - Section 1: Subject Cards List (Main Focus)
                    subjectCardsSection

                    // MARK: - Section 2: Session & Inline Exams (at bottom of same screen)
                    if !store.activeSubjects.isEmpty {
                        sessionGradingSection
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
            }
        }
        .navigationTitle(store.activeSemester?.title ?? "Трекер практик")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    HapticManager.shared.touchGlass()
                    onOpenSettings()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
        }
        .sheet(isPresented: $showSubjectCreateSheet) {
            SubjectEditView(store: store)
        }
        .sheet(isPresented: $showTaskCreateSheet) {
            TaskEditView(store: store, defaultSubjectId: selectedSubjectForNewTask)
        }
    }

    // MARK: - Compact Top Summary Bar
    private var compactTopSummary: some View {
        HStack(spacing: 10) {
            // Overall Progress Bar & Percentage
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Общий прогресс")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("\(store.overallProgressPercentage)%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(store.theme.preset.primaryAccent)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 5)
                        Capsule()
                            .fill(store.theme.preset.primaryAccent)
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(store.overallProgressPercentage) / 100.0)), height: 5)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 24)
                .background(Color.white.opacity(0.15))

            // Countdown to Session
            if let sem = store.activeSemester {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 13))
                        .foregroundColor(.cyan)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("До сессии")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        Text("\(sem.daysRemainingToSession) дн.")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
                )
        )
    }

    // MARK: - Section 1: Subject Cards List
    private var subjectCardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ПРЕДМЕТЫ И ПРАКТИКИ")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                Button {
                    showSubjectCreateSheet = true
                    HapticManager.shared.touchGlass()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "plus")
                        Text("Предмет")
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(store.theme.preset.primaryAccent)
                }
            }
            .padding(.horizontal, 4)

            if store.activeSubjects.isEmpty {
                emptySubjectsPrompt
            } else {
                ForEach(store.activeSubjects) { subject in
                    subjectCard(subject: subject)
                }
            }
        }
    }

    // MARK: - Single Subject Card (Tappable -> SubjectDetailView)
    private func subjectCard(subject: Subject) -> some View {
        let subjectTasks = store.tasks.filter { $0.subjectId == subject.id }
        let completedCount = subjectTasks.filter { $0.status.isFinished }.count
        let progress = subjectTasks.isEmpty ? 0.0 : Double(completedCount) / Double(subjectTasks.count)

        return NavigationLink {
            SubjectDetailView(store: store, subjectId: subject.id)
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                // Header: Color icon + Title + Type badge + Arrow
                HStack(spacing: 8) {
                    Circle()
                        .fill(subject.themeColor)
                        .frame(width: 8, height: 8)

                    Text(subject.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text(subject.assessmentType.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(subject.assessmentType.badgeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(subject.assessmentType.badgeColor.opacity(0.15)))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.35))
                }

                // Thin Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 4)
                        Capsule()
                            .fill(subject.themeColor)
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(progress))), height: 4)
                    }
                }
                .frame(height: 4)

                // Quick stats: Practices done + Attendance summary
                HStack(spacing: 12) {
                    Text("Практик: \(completedCount)/\(subjectTasks.count)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))

                    Text("•")
                        .foregroundColor(.white.opacity(0.3))

                    Text("Лекции: \(subject.lecturesAttended)/\(subject.lecturesTotal)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue.opacity(0.9))

                    Text("•")
                        .foregroundColor(.white.opacity(0.3))

                    Text("Практики: \(subject.practicesAttended)/\(subject.practicesTotal)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green.opacity(0.9))

                    Spacer()
                }

                // Inline tasks preview (first 2-3 tasks with direct checkmarks)
                if !subjectTasks.isEmpty {
                    Divider().background(Color.white.opacity(0.06))

                    VStack(spacing: 4) {
                        ForEach(subjectTasks.prefix(3)) { task in
                            HStack(spacing: 6) {
                                Button {
                                    store.toggleTaskCompletion(task)
                                } label: {
                                    Image(systemName: task.status.isFinished ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 14))
                                        .foregroundColor(task.status.isFinished ? .green : .white.opacity(0.35))
                                }
                                .buttonStyle(PlainButtonStyle())

                                Text(task.title)
                                    .font(.system(size: 12, weight: task.status.isFinished ? .regular : .medium))
                                    .foregroundColor(task.status.isFinished ? .white.opacity(0.35) : .white.opacity(0.85))
                                    .strikethrough(task.status.isFinished, color: .white.opacity(0.3))
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(.vertical, 1)
                        }

                        if subjectTasks.count > 3 {
                            Text("+ еще \(subjectTasks.count - 3) заданий...")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.cyan.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.8)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Section 2: Session & Inline Exams / Tests
    private var sessionGradingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("СЕССИЯ И АТТЕСТАЦИЯ")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                if let gpa = sessionAverageGPA {
                    Text("Средний балл: \(gpa)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)

            VStack(spacing: 8) {
                ForEach(store.activeSubjects) { subject in
                    compactSessionSubjectRow(subject: subject)
                }
            }
        }
    }

    private func compactSessionSubjectRow(subject: Subject) -> some View {
        let sessionItem = store.getSessionItem(for: subject.id)
        let isExam = subject.assessmentType == .exam || subject.assessmentType == .diffTest

        return HStack(spacing: 10) {
            // Admission Checkbox
            Button {
                store.toggleAdmission(for: subject.id)
            } label: {
                Image(systemName: subject.isAdmittedToExam ? "checkmark.shield.fill" : "shield")
                    .font(.system(size: 16))
                    .foregroundColor(subject.isAdmittedToExam ? .green : .white.opacity(0.3))
            }
            .buttonStyle(PlainButtonStyle())

            // Subject Name & Type
            VStack(alignment: .leading, spacing: 2) {
                Text(subject.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(subject.assessmentType.rawValue)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Inline Quick Grading Buttons
            if isExam {
                HStack(spacing: 4) {
                    ForEach([2, 3, 4, 5], id: \.self) { gradeVal in
                        let isSelected = sessionItem?.grade?.rawValue == gradeVal
                        Button {
                            var item = sessionItem ?? SessionItem(subjectId: subject.id)
                            item.grade = isSelected ? nil : ExamGrade(rawValue: gradeVal)
                            store.updateSessionItem(item)
                            HapticManager.shared.touchGlass()
                        } label: {
                            Text("\(gradeVal)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                                .frame(width: 26, height: 26)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isSelected ? (gradeVal == 5 ? Color.green : (gradeVal == 4 ? Color.blue : (gradeVal == 3 ? Color.orange : Color.red))) : Color.white.opacity(0.06))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            } else {
                let isPassed = sessionItem?.testResult == .passed
                Button {
                    var item = sessionItem ?? SessionItem(subjectId: subject.id)
                    item.testResult = isPassed ? .failed : .passed
                    store.updateSessionItem(item)
                    HapticManager.shared.touchGlass()
                } label: {
                    Text(isPassed ? "Сдал" : "Не сдал")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(isPassed ? .green : .white.opacity(0.5))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(isPassed ? Color.green.opacity(0.18) : Color.white.opacity(0.06)))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.8)
                )
        )
    }

    private var sessionAverageGPA: String? {
        let grades = store.activeSessionItems.compactMap { $0.grade?.rawValue }
        guard !grades.isEmpty else { return nil }
        let avg = Double(grades.reduce(0, +)) / Double(grades.count)
        return String(format: "%.2f", avg)
    }

    private var emptySubjectsPrompt: some View {
        VStack(spacing: 8) {
            Text("Список предметов пуст")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

            Text("Нажмите «+ Предмет» или откройте настройки вверху для загрузки демо-данных.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))
    }
}
