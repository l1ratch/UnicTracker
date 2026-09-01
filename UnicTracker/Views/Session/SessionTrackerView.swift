import SwiftUI

public struct SessionTrackerView: View {
    @ObservedObject var store: DataStore
    @State private var selectedSubjectForGrading: Subject? = nil
    @State private var showFinishSemesterSheet: Bool = false

    public init(store: DataStore) {
        self.store = store
    }

    private var examsList: [Subject] {
        store.activeSubjects.filter { $0.assessmentType == .exam || $0.assessmentType == .diffTest }
    }

    private var testsList: [Subject] {
        store.activeSubjects.filter { $0.assessmentType == .test || $0.assessmentType == .credit || $0.assessmentType == .courseWork }
    }

    public var body: some View {
        NavigationView {
            ZStack {
                MeshGradientBackground(store: store)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // MARK: - Session Overview Glass Card
                        sessionSummaryHeader

                        // MARK: - Exams Section (Экзамены)
                        if !examsList.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Label("ЭКЗАМЕНЫ", systemImage: "graduationcap.fill")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.6))
                                    Spacer()
                                    Text("\(examsPassedCount)/\(examsList.count) сдано")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.cyan)
                                }

                                ForEach(examsList) { subject in
                                    sessionSubjectCard(subject: subject)
                                }
                            }
                        }

                        // MARK: - Tests Section (Зачеты)
                        if !testsList.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Label("ЗАЧЕТЫ И КУРСОВЫЕ", systemImage: "checkmark.shield.fill")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.6))
                                    Spacer()
                                    Text("\(testsPassedCount)/\(testsList.count) зачтено")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.green)
                                }

                                ForEach(testsList) { subject in
                                    sessionSubjectCard(subject: subject)
                                }
                            }
                        }

                        if store.activeSubjects.isEmpty {
                            emptySessionView
                        } else {
                            // Finish Semester Glass Action Banner
                            finishSemesterBanner
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Сессия и экзамены")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedSubjectForGrading) { subject in
                if let item = store.getSessionItem(for: subject.id) {
                    GradePickerSheet(store: store, subject: subject, sessionItem: item)
                }
            }
            .sheet(isPresented: $showFinishSemesterSheet) {
                FinishSemesterModal(store: store)
            }
        }
    }

    // MARK: - Session Summary Header
    private var sessionSummaryHeader: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ИТОГОВАЯ АТТЕСТАЦИЯ")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))

                    Text(store.activeSemester?.title ?? "Текущий семестр")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                if let gpa = averageGPAString {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Средний балл")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text(gpa)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.yellow)
                    }
                }
            }

            Divider()
                .background(Color.white.opacity(0.1))

            HStack(spacing: 12) {
                summaryStatPill(
                    icon: "checkmark.circle.fill",
                    title: "Допуски",
                    value: "\(admissionsCount)/\(store.activeSubjects.count)",
                    tint: .blue
                )

                summaryStatPill(
                    icon: "graduationcap.fill",
                    title: "Экзамены",
                    value: "\(examsPassedCount)/\(examsList.count)",
                    tint: .purple
                )

                summaryStatPill(
                    icon: "checkmark.seal.fill",
                    title: "Зачеты",
                    value: "\(testsPassedCount)/\(testsList.count)",
                    tint: .green
                )
            }
        }
        .padding(18)
        .liquidGlass(
            cornerRadius: 22,
            depth: store.theme.glassDepth,
            tint: store.theme.preset.primaryAccent,
            specular: true,
            glow: 0.4
        )
    }

    private func summaryStatPill(icon: String, title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(tint)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - Individual Subject Session Card
    private func sessionSubjectCard(subject: Subject) -> some View {
        let sessionItem = store.getSessionItem(for: subject.id)

        return Button {
            selectedSubjectForGrading = subject
            HapticManager.shared.touchGlass()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 12) {
                    // Subject Icon with Color Circle
                    ZStack {
                        Circle()
                            .fill(subject.themeColor.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(Circle().strokeBorder(subject.themeColor.opacity(0.4), lineWidth: 1))

                        Image(systemName: subject.iconName)
                            .font(.system(size: 18))
                            .foregroundColor(subject.themeColor)
                    }

                    // Title & Teacher
                    VStack(alignment: .leading, spacing: 2) {
                        Text(subject.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)

                        if !subject.teacherName.isEmpty {
                            Text(subject.teacherName)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    Spacer()

                    // Grade or Status Badge
                    if let grade = sessionItem?.grade {
                        Text("\(grade.rawValue)")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(grade.color)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(grade.color.opacity(0.2)))
                            .overlay(Circle().strokeBorder(grade.color.opacity(0.6), lineWidth: 1.5))
                    } else if let testRes = sessionItem?.testResult, testRes != .pending {
                        Text(testRes.rawValue)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(testRes.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(testRes.color.opacity(0.2)))
                    } else {
                        Text("Не оценено")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.06)))
                    }
                }

                // Sub-card details: Admission toggle + tickets + date
                HStack {
                    // Admission Indicator
                    Button {
                        store.toggleAdmission(for: subject.id)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: subject.isAdmittedToExam ? "checkmark.circle.fill" : "xmark.circle.fill")
                            Text(subject.isAdmittedToExam ? "Допуск есть" : "Без допуска")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(subject.isAdmittedToExam ? .green : .orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(subject.isAdmittedToExam ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()

                    // Tickets progress
                    if let item = sessionItem, item.ticketsTotal > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "list.clipboard")
                                .font(.system(size: 11))
                            Text("\(item.ticketsLearned)/\(item.ticketsTotal) билетов")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.cyan.opacity(0.8))
                    }

                    // Exam Date
                    if let date = sessionItem?.examDate {
                        Text(date.formatted(date: .numeric, time: .omitted))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(14)
            .liquidGlass(cornerRadius: 18, depth: store.theme.glassDepth, tint: subject.themeColor)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Finish Semester Action Banner
    private var finishSemesterBanner: some View {
        VStack(spacing: 8) {
            Button {
                showFinishSemesterSheet = true
                HapticManager.shared.touchGlass()
            } label: {
                HStack {
                    Image(systemName: "archivebox.fill")
                    Text("Завершить семестр и архивировать")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(GlassButtonStyle(tint: Color.purple, cornerRadius: 16, isProminent: true))

            Text("Все результаты и статистика сохранятся в локальный архив.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top, 14)
    }

    private var emptySessionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "graduationcap")
                .font(.system(size: 40))
                .foregroundColor(.purple.opacity(0.7))
            Text("Нет дисциплин для сессии")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Добавьте дисциплины с формой контроля «Экзамен» или «Зачет» в Конструкторе.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .liquidGlass(cornerRadius: 20, depth: store.theme.glassDepth)
        .padding(.top, 20)
    }

    // MARK: - Helpers
    private var admissionsCount: Int {
        store.activeSubjects.filter { $0.isAdmittedToExam }.count
    }

    private var examsPassedCount: Int {
        examsList.filter { sub in
            if let item = store.getSessionItem(for: sub.id), let g = item.grade {
                return g != .unsatisfactory
            }
            return false
        }.count
    }

    private var testsPassedCount: Int {
        testsList.filter { sub in
            if let item = store.getSessionItem(for: sub.id) {
                return item.testResult == .passed
            }
            return false
        }.count
    }

    private var averageGPAString: String? {
        let gradedExams = store.activeSessionItems.compactMap { $0.grade?.rawValue }
        guard !gradedExams.isEmpty else { return nil }
        let avg = Double(gradedExams.reduce(0, +)) / Double(gradedExams.count)
        return String(format: "%.2f", avg)
    }
}
