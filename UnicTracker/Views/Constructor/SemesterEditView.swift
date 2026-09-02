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

    public init(store: DataStore) {
        self.store = store
        if let current = store.activeSemester {
            self._title = State(initialValue: current.title)
            self._courseNumber = State(initialValue: current.courseNumber)
            self._semesterNumber = State(initialValue: current.semesterNumber)
            self._academicYear = State(initialValue: current.academicYear)
            self._startDate = State(initialValue: current.startDate)
            self._endDate = State(initialValue: current.endDate)
        } else {
            self._title = State(initialValue: "Осенний семестр")
            self._courseNumber = State(initialValue: 1)
            self._semesterNumber = State(initialValue: 1)
            self._academicYear = State(initialValue: "2026/2027")
            self._startDate = State(initialValue: Date())
            let cal = Calendar.current
            self._endDate = State(initialValue: cal.date(byAdding: .month, value: 5, to: Date()) ?? Date())
        }
    }

    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - Section: Title & Academic Period
                Section("Основная информация") {
                    TextField("Название (напр. 3 Курс • Осенний семестр)", text: $title)
                        .font(.system(size: 15, weight: .semibold))

                    Stepper("Курс: \(courseNumber)", value: $courseNumber, in: 1...6)
                    Stepper("Семестр: \(semesterNumber)", value: $semesterNumber, in: 1...12)
                    TextField("Учебный год", text: $academicYear)
                }

                // MARK: - Section: Dates (Separated Start and End)
                Section("Сроки семестра") {
                    DatePicker(
                        "Начало семестра",
                        selection: $startDate,
                        displayedComponents: [.date]
                    )

                    DatePicker(
                        "Окончание семестра",
                        selection: $endDate,
                        displayedComponents: [.date]
                    )
                }
            }
            .navigationTitle("Настройка семестра")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
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
            current.academicYear = academicYear
            current.startDate = startDate
            current.endDate = endDate
            store.semesters[index] = current
            store.persist()
        } else {
            store.createSemester(
                title: title,
                course: courseNumber,
                semesterNumber: semesterNumber,
                startDate: startDate,
                endDate: endDate
            )
        }
        HapticManager.shared.notifySuccess()
        dismiss()
    }
}
