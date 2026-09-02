import SwiftUI

public struct SubjectEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: DataStore

    @State private var subject: Subject
    @State private var isNewSubject: Bool

    // Batch generator fields
    @State private var enableBatchGen: Bool = false
    @State private var batchCount: Int = 6
    @State private var batchCategory: TaskCategory = .lab
    @State private var batchPrefix: String = "Лабораторная работа"

    private let availableIcons = [
        "network", "cpu.fill", "memorychip.fill", "cylinder.split.1x2.fill",
        "function", "terminal.fill", "atom", "chart.bar.xaxis",
        "book.fill", "graduationcap.fill", "shield.lefthalf.filled", "globe"
    ]

    public init(store: DataStore, subjectToEdit: Subject? = nil) {
        self.store = store
        if let existing = subjectToEdit {
            self._subject = State(initialValue: existing)
            self._isNewSubject = State(initialValue: false)
        } else {
            let activeSemId = store.activeSemester?.id ?? UUID()
            self._subject = State(initialValue: Subject(
                semesterId: activeSemId,
                name: "",
                shortCode: "",
                iconName: "network",
                colorHex: SubjectColorOption.cyan.rawValue,
                assessmentType: .exam,
                importance: .medium
            ))
            self._isNewSubject = State(initialValue: true)
        }
    }

    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - Section: Names (Short Code & Full Name)
                Section("Название и краткий код") {
                    HStack {
                        Text("Код:")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.cyan)

                        TextField("КС, ОС, БД...", text: $subject.shortCode)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .textInputAutocapitalization(.characters)
                            .frame(maxWidth: 120)

                        Spacer()

                        Text("Отображается на карточке")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    TextField("Полное название предмета (Компьютерные сети)", text: $subject.name)
                        .font(.system(size: 14))
                }

                // MARK: - Section: Importance Level (Уровень важности)
                Section("Уровень важности предмета") {
                    Picker("Важность", selection: $subject.importance) {
                        ForEach(SubjectImportance.allCases) { imp in
                            Text(imp.rawValue).tag(imp)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(subject.importance.color)
                            .frame(width: 8, height: 8)
                        Text("Предметы с более высокой важностью показываются первыми в списке.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }

                // MARK: - Section: Color & Icon
                Section("Цвет и иконка") {
                    // Color Palette
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(SubjectColorOption.allCases) { opt in
                                let isSelected = subject.colorHex == opt.rawValue
                                Button {
                                    subject.colorHex = opt.rawValue
                                    HapticManager.shared.touchGlass()
                                } label: {
                                    Circle()
                                        .fill(opt.color)
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle().stroke(Color.white, lineWidth: isSelected ? 2.5 : 0)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // Icon Grid
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(availableIcons, id: \.self) { icon in
                                let isSelected = subject.iconName == icon
                                Button {
                                    subject.iconName = icon
                                    HapticManager.shared.touchGlass()
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                                        .frame(width: 36, height: 36)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isSelected ? subject.themeColor.opacity(0.4) : Color.white.opacity(0.06))
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // MARK: - Section: Teacher & Room
                Section("Преподаватель и аудитория") {
                    TextField("ФИО преподавателя", text: $subject.teacherName)
                    TextField("Аудитория или ссылка", text: $subject.roomOrLink)
                    Picker("Форма контроля", selection: $subject.assessmentType) {
                        ForEach(AssessmentType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }

                // MARK: - Section: Attendance Norms
                Section("Нормы посещаемости") {
                    Stepper("Всего лекций в плане: \(subject.lecturesTotal)", value: $subject.lecturesTotal, in: 1...100)
                    Stepper("Всего практик в плане: \(subject.practicesTotal)", value: $subject.practicesTotal, in: 1...100)
                }

                // MARK: - Section: Batch Generator (For new subjects)
                if isNewSubject {
                    Section("Быстрая генерация практик") {
                        Toggle("Сгенерировать задания сразу", isOn: $enableBatchGen)

                        if enableBatchGen {
                            Picker("Тип работ", selection: $batchCategory) {
                                ForEach(TaskCategory.allCases) { cat in
                                    Text(cat.rawValue).tag(cat)
                                }
                            }
                            TextField("Префикс", text: $batchPrefix)
                            Stepper("Количество: \(batchCount)", value: $batchCount, in: 1...30)
                        }
                    }
                }

                // MARK: - Delete Subject Button
                if !isNewSubject {
                    Section {
                        Button(role: .destructive) {
                            store.deleteSubject(subject)
                            dismiss()
                        } label: {
                            Label("Удалить предмет", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(isNewSubject ? "Новый предмет" : "Редактировать предмет")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveSubjectAndProceed()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(subject.name.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.3) : .cyan)
                    .disabled(subject.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveSubjectAndProceed() {
        if subject.shortCode.trimmingCharacters(in: .whitespaces).isEmpty {
            subject.shortCode = String(subject.name.prefix(4)).uppercased()
        }
        store.saveSubject(subject)

        if isNewSubject && enableBatchGen {
            store.generateBatchTasks(
                subjectId: subject.id,
                category: batchCategory,
                count: batchCount,
                prefix: batchPrefix
            )
        }

        HapticManager.shared.notifySuccess()
        dismiss()
    }
}
