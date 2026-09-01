import SwiftUI

public struct ConstructorHubView: View {
    @ObservedObject var store: DataStore

    @State private var showSemesterEditSheet: Bool = false
    @State private var showSubjectEditSheet: Bool = false
    @State private var showTaskEditSheet: Bool = false
    @State private var subjectToEdit: Subject? = nil
    @State private var selectedSubjectForNewTask: UUID? = nil

    public init(store: DataStore) {
        self.store = store
    }

    public var body: some View {
        NavigationView {
            ZStack {
                MeshGradientBackground(store: store)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Semester Header Config Card
                        semesterInfoCard

                        // Quick Builder Action Pills
                        quickActionPills

                        // Subjects and their tasks builder list
                        subjectsBuilderSection

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Конструктор")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSemesterEditSheet) {
                SemesterEditView(store: store)
            }
            .sheet(isPresented: $showSubjectEditSheet) {
                SubjectEditView(store: store, subjectToEdit: subjectToEdit)
            }
            .sheet(isPresented: $showTaskEditSheet) {
                TaskEditView(store: store, defaultSubjectId: selectedSubjectForNewTask)
            }
        }
    }

    // MARK: - Semester Info Card
    private var semesterInfoCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("АКТИВНЫЙ СЕМЕСТР")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))

                    Text(store.activeSemester?.title ?? "Семестр не создан")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                Button {
                    showSemesterEditSheet = true
                    HapticManager.shared.touchGlass()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Изменить")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.cyan.opacity(0.15)))
                }
                .buttonStyle(PlainButtonStyle())
            }

            if let sem = store.activeSemester {
                HStack(spacing: 14) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text("\(sem.startDate.formatted(date: .abbreviated, time: .omitted)) — \(sem.endDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Text("Курс \(sem.courseNumber)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.yellow.opacity(0.15)))
                }
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20, depth: store.theme.glassDepth, tint: store.theme.preset.primaryAccent)
    }

    // MARK: - Quick Action Pills
    private var quickActionPills: some View {
        HStack(spacing: 10) {
            Button {
                subjectToEdit = nil
                showSubjectEditSheet = true
                HapticManager.shared.touchGlass()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.badge.plus")
                    Text("+ Предмет")
                }
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(GlassButtonStyle(tint: store.theme.preset.primaryAccent, cornerRadius: 14, isProminent: true))

            Button {
                selectedSubjectForNewTask = store.activeSubjects.first?.id
                showTaskEditSheet = true
                HapticManager.shared.touchGlass()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.square.fill")
                    Text("+ Задание")
                }
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.cyan)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(GlassButtonStyle(tint: Color.cyan.opacity(0.2), cornerRadius: 14))
            .disabled(store.activeSubjects.isEmpty)
        }
    }

    // MARK: - Subjects Builder Section
    private var subjectsBuilderSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("ПРЕДМЕТЫ И СТРУКТУРА (\(store.activeSubjects.count))")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
            }

            if store.activeSubjects.isEmpty {
                VStack(spacing: 8) {
                    Text("В семестре пока нет дисциплин")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    Text("Нажмите «+ Предмет», чтобы добавить первую пару и сгенерировать практические работы.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .liquidGlass(cornerRadius: 18, depth: store.theme.glassDepth)
            } else {
                ForEach(store.activeSubjects) { subject in
                    subjectStructureCard(subject: subject)
                }
            }
        }
    }

    private func subjectStructureCard(subject: Subject) -> some View {
        let subjectTasks = store.tasks.filter { $0.subjectId == subject.id }

        return VStack(alignment: .leading, spacing: 10) {
            // Subject header row
            HStack {
                ZStack {
                    Circle()
                        .fill(subject.themeColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Image(systemName: subject.iconName)
                        .font(.system(size: 15))
                        .foregroundColor(subject.themeColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(subject.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("\(subject.assessmentType.rawValue) • \(subjectTasks.count) заданий")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Button {
                    subjectToEdit = subject
                    showSubjectEditSheet = true
                    HapticManager.shared.touchGlass()
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(4)
                }
                .buttonStyle(PlainButtonStyle())
            }

            Divider().background(Color.white.opacity(0.08))

            // Tasks Preview / Add task to this subject
            VStack(spacing: 6) {
                ForEach(subjectTasks.prefix(4)) { task in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(task.priority.color)
                            .frame(width: 6, height: 6)
                        Text(task.title)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                        Spacer()
                        Text(task.status.rawValue)
                            .font(.system(size: 11))
                            .foregroundColor(task.status.statusColor)
                    }
                    .padding(.vertical, 2)
                }

                if subjectTasks.count > 4 {
                    Text("+ еще \(subjectTasks.count - 4) заданий")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)
                }
            }

            // Quick add task button for this specific subject
            Button {
                selectedSubjectForNewTask = subject.id
                showTaskEditSheet = true
                HapticManager.shared.touchGlass()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Добавить задание к «\(subject.shortCode)»")
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(subject.themeColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(subject.themeColor.opacity(0.1))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 4)
        }
        .padding(14)
        .liquidGlass(cornerRadius: 18, depth: store.theme.glassDepth, tint: subject.themeColor)
    }
}
