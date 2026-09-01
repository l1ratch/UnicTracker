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
        "cpu.fill", "memorychip.fill", "cylinder.split.1x2.fill", "function",
        "terminal.fill", "network", "atom", "chart.bar.xaxis",
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
                iconName: "book.fill",
                colorHex: SubjectColorOption.cyan.rawValue,
                assessmentType: .exam
            ))
            self._isNewSubject = State(initialValue: true)
        }
    }

    public var body: some View {
        NavigationView {
            ZStack {
                MeshGradientBackground(store: store)

                ScrollView {
                    VStack(spacing: 20) {
                        // Main Info Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ДИСЦИПЛИНА")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))

                            TextField("Название (напр. Компьютерные сети)", text: $subject.name)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))

                            HStack {
                                TextField("Код (КС)", text: $subject.shortCode)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .frame(width: 90)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))

                                Spacer()

                                Text("Краткий тег на карточке")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth, tint: subject.themeColor)

                        // Icon and Color Customization Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("СТИЛЬ И ИКОНКА")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))

                            // Color Picker
                            HStack(spacing: 10) {
                                ForEach(SubjectColorOption.allCases) { opt in
                                    let isSelected = subject.colorHex == opt.rawValue
                                    Button {
                                        subject.colorHex = opt.rawValue
                                        HapticManager.shared.touchGlass()
                                    } label: {
                                        Circle()
                                            .fill(opt.color)
                                            .frame(width: 32, height: 32)
                                            .overlay(
                                                Circle().stroke(Color.white, lineWidth: isSelected ? 2.5 : 0)
                                            )
                                            .shadow(color: opt.color.opacity(isSelected ? 0.8 : 0.2), radius: 6)
                                    }
                                }
                            }

                            Divider().background(Color.white.opacity(0.1))

                            // Icon Picker Grid
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    let isSelected = subject.iconName == icon
                                    Button {
                                        subject.iconName = icon
                                        HapticManager.shared.touchGlass()
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.system(size: 18))
                                            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                                            .frame(width: 44, height: 44)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(isSelected ? subject.themeColor.opacity(0.4) : Color.white.opacity(0.06))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .strokeBorder(isSelected ? subject.themeColor : Color.clear, lineWidth: 1)
                                                    )
                                            )
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)

                        // Assessment Type Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ФОРМА ИТОГОВОГО КОНТРОЛЯ")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))

                            ForEach(AssessmentType.allCases) { type in
                                let isSelected = subject.assessmentType == type
                                Button {
                                    subject.assessmentType = type
                                    HapticManager.shared.touchGlass()
                                } label: {
                                    HStack {
                                        Image(systemName: type.iconName)
                                            .foregroundColor(type.badgeColor)
                                            .frame(width: 24)

                                        Text(type.rawValue)
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(isSelected ? .white : .white.opacity(0.8))

                                        Spacer()

                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.cyan)
                                        }
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)

                        // Teacher & Details
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ПРЕПОДАВАТЕЛЬ И АУДИТОРИЯ")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))

                            TextField("ФИО преподавателя", text: $subject.teacherName)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))

                            TextField("Аудитория или ссылка на Zoom/LMS", text: $subject.roomOrLink)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                        }
                        .padding(18)
                        .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth)

                        // 1-Click Batch Task Generator (Available on creation)
                        if isNewSubject {
                            VStack(alignment: .leading, spacing: 14) {
                                Toggle("Сгенерировать задания сразу", isOn: $enableBatchGen)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)

                                if enableBatchGen {
                                    Divider().background(Color.white.opacity(0.1))

                                    Picker("Тип работ", selection: $batchCategory) {
                                        ForEach(TaskCategory.allCases) { cat in
                                            Text(cat.rawValue).tag(cat)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .accentColor(.cyan)

                                    TextField("Префикс названия", text: $batchPrefix)
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))

                                    Stepper("Количество: \(batchCount)", value: $batchCount, in: 1...30)
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(18)
                            .liquidGlass(cornerRadius: 22, depth: store.theme.glassDepth, tint: Color.cyan)
                        }

                        // Delete Subject Button
                        if !isNewSubject {
                            Button {
                                store.deleteSubject(subject)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Удалить дисциплину")
                                }
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(GlassButtonStyle(tint: Color.red.opacity(0.3), cornerRadius: 18))
                            .padding(.top, 10)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle(isNewSubject ? "Новая дисциплина" : "Редактировать предмет")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveAndProceed()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(subject.name.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.3) : .cyan)
                    .disabled(subject.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveAndProceed() {
        if subject.shortCode.isEmpty {
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
