import SwiftUI

public struct SemesterEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: DataStore

    @State private var title: String
    @State private var courseNumber: Int
    @State private var semesterNumber: Int
    @State private var academicYear: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var sessionStartDate: Date

    public init(store: DataStore) {
        self.store = store
        if let current = store.activeSemester {
            self._title = State(initialValue: current.title)
            self._courseNumber = State(initialValue: current.courseNumber)
            self._semesterNumber = State(initialValue: current.semesterNumber)
            self._academicYear = State(initialValue: current.academicYear)
            self._startDate = State(initialValue: current.startDate)
            self._endDate = State(initialValue: current.endDate)
            self._sessionStartDate = State(initialValue: current.sessionStartDate ?? current.endDate)
        } else {
            self._title = State(initialValue: "1 Семестр")
            self._courseNumber = State(initialValue: 1)
            self._semesterNumber = State(initialValue: 1)
            self._academicYear = State(initialValue: "2026/2027")
            self._startDate = State(initialValue: Date())
            let cal = Calendar.current
            self._endDate = State(initialValue: cal.date(byAdding: .month, value: 5, to: Date()) ?? Date())
            self._sessionStartDate = State(initialValue: cal.date(byAdding: .month, value: 4, to: Date()) ?? Date())
        }
    }

    public var body: some View {
        NavigationView {
            ZStack {
                MeshGradientBackground(store: store)

                ScrollView {
                    VStack(spacing: 20) {
                        // Title Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("НАЗВАНИЕ СЕМЕСТРА")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))

                            TextField("Название (напр. 3 Курс • Осенний семестр)", text: $title)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))

                            HStack(spacing: 12) {
                                Stepper("Курс: \(courseNumber)", value: $courseNumber, in: 1...6)
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))

                            HStack(spacing: 12) {
                                Stepper("Семестр: \(semesterNumber)", value: $semesterNumber, in: 1...12)
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)

                        // Dates Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("СРОКИ ОБУЧЕНИЯ И СЕССИИ")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))

                            DatePicker("Начало учебы", selection: $startDate, displayedComponents: .date)
                                .foregroundColor(.white)

                            DatePicker("Начало сессии", selection: $sessionStartDate, displayedComponents: .date)
                                .foregroundColor(.white)

                            DatePicker("Окончание семестра", selection: $endDate, displayedComponents: .date)
                                .foregroundColor(.white)
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Настройка семестра")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveSemester()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(title.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.3) : .cyan)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveSemester() {
        if var current = store.activeSemester,
           let index = store.semesters.firstIndex(where: { $0.id == current.id }) {
            current.title = title
            current.courseNumber = courseNumber
            current.semesterNumber = semesterNumber
            current.startDate = startDate
            current.endDate = endDate
            current.sessionStartDate = sessionStartDate
            store.semesters[index] = current
            store.persist()
        } else {
            store.createSemester(
                title: title,
                course: courseNumber,
                semesterNumber: semesterNumber,
                startDate: startDate,
                endDate: endDate,
                sessionStart: sessionStartDate
            )
        }
        HapticManager.shared.notifySuccess()
        dismiss()
    }
}
