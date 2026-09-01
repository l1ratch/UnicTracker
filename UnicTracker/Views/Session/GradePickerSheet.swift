import SwiftUI

public struct GradePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: DataStore
    public var subject: Subject
    @State var sessionItem: SessionItem

    public init(store: DataStore, subject: Subject, sessionItem: SessionItem) {
        self.store = store
        self.subject = subject
        self._sessionItem = State(initialValue: sessionItem)
    }

    public var body: some View {
        NavigationView {
            ZStack {
                MeshGradientBackground(store: store)

                ScrollView {
                    VStack(spacing: 20) {
                        // Subject Summary Card
                        VStack(spacing: 8) {
                            Image(systemName: subject.assessmentType.iconName)
                                .font(.system(size: 32))
                                .foregroundColor(subject.themeColor)

                            Text(subject.name)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            HStack {
                                Text(subject.assessmentType.rawValue)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(subject.assessmentType.badgeColor)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(subject.assessmentType.badgeColor.opacity(0.15)))

                                Text(subject.isAdmittedToExam ? "✓ Допуск получен" : "✕ Нет допуска")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(subject.isAdmittedToExam ? .green : .orange)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(subject.isAdmittedToExam ? Color.green.opacity(0.15) : Color.orange.opacity(0.15)))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth, tint: subject.themeColor)

                        // Evaluation / Grade Picker Section
                        if subject.assessmentType == .exam || subject.assessmentType == .diffTest {
                            examGradeSelector
                        } else {
                            testResultSelector
                        }

                        // Exam Preparation / Tickets Tracker
                        ticketsPreparationCard

                        // Exam Date & Retake options
                        dateAndOptionsCard

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Итоговая аттестация")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        store.updateSessionItem(sessionItem)
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                    .font(.system(size: 16, weight: .bold))
                }
            }
        }
    }

    // MARK: - Exam Grade Selector (5, 4, 3, 2)
    private var examGradeSelector: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ИТОГОВАЯ ОЦЕНКА")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            HStack(spacing: 10) {
                ForEach(ExamGrade.allCases) { grade in
                    let isSelected = sessionItem.grade == grade
                    Button {
                        sessionItem.grade = grade
                        HapticManager.shared.touchGlass()
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(grade.rawValue)")
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                            Text(grade.title.components(separatedBy: " ").last ?? "")
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                        }
                        .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isSelected ? grade.color.opacity(0.4) : Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(isSelected ? grade.color : Color.white.opacity(0.12), lineWidth: 1.5)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            if sessionItem.grade != nil {
                Button {
                    sessionItem.grade = nil
                    HapticManager.shared.touchGlass()
                } label: {
                    Text("Сбросить оценку")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 4)
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)
    }

    // MARK: - Test Result Selector (Сдал / Не сдал)
    private var testResultSelector: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("РЕЗУЛЬТАТ ЗАЧЕТА")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            HStack(spacing: 12) {
                ForEach(TestResult.allCases) { result in
                    let isSelected = sessionItem.testResult == result
                    Button {
                        sessionItem.testResult = result
                        HapticManager.shared.touchGlass()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: result.iconName)
                            Text(result.rawValue)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isSelected ? result.color.opacity(0.4) : Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(isSelected ? result.color : Color.white.opacity(0.12), lineWidth: 1.5)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)
    }

    // MARK: - Tickets Preparation Card
    private var ticketsPreparationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("ПОДГОТОВКА ВОПРОСОВ И БИЛЕТОВ")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                Text("\(Int(sessionItem.ticketPreparationRatio * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
            }

            ProgressView(value: sessionItem.ticketPreparationRatio)
                .progressViewStyle(LinearProgressViewStyle(tint: Color.cyan))

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Выучено билетов:")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    Stepper("\(sessionItem.ticketsLearned)", value: $sessionItem.ticketsLearned, in: 0...max(sessionItem.ticketsTotal, 1))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Всего билетов:")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    Stepper("\(sessionItem.ticketsTotal)", value: $sessionItem.ticketsTotal, in: 0...100)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)
    }

    // MARK: - Date & Options
    private var dateAndOptionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ДАТА И ДОПОЛНИТЕЛЬНО")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            DatePicker(
                "Дата аттестации",
                selection: Binding(
                    get: { sessionItem.examDate ?? Date() },
                    set: { sessionItem.examDate = $0 }
                ),
                displayedComponents: [.date, .hourAndMinute]
            )
            .foregroundColor(.white)

            Toggle("Статус: Пересдача", isOn: $sessionItem.isRetake)
                .foregroundColor(.white)
        }
        .padding(18)
        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)
    }
}
