import SwiftUI

public struct MainTrackerView: View {
    @ObservedObject var store: DataStore
    @State private var selectedTaskForDetail: StudyTask? = nil
    @State private var showCreateTaskSheet: Bool = false
    @State private var showCreateSubjectSheet: Bool = false

    public init(store: DataStore) {
        self.store = store
    }

    public var body: some View {
        NavigationView {
            ZStack {
                MeshGradientBackground(store: store)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // MARK: - Hero Stats Glass Card (Inspired by reference web app)
                        heroStatsCard

                        // MARK: - Subject Filter Pills Carousel
                        if !store.activeSubjects.isEmpty {
                            subjectFilterBar
                        }

                        // MARK: - Status Filter Tabs & Search
                        filterAndSearchBar

                        // MARK: - Task Cards List
                        if store.filteredTasks.isEmpty {
                            emptyStateView
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(store.filteredTasks) { task in
                                    TaskRowView(store: store, task: task) {
                                        selectedTaskForDetail = task
                                        HapticManager.shared.touchGlass()
                                    }
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                }
                            }
                        }

                        Spacer(minLength: 80) // TabBar padding
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.activeSemester?.title ?? "ТРЕКЕР УНИКА")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)

                        if let year = store.activeSemester?.academicYear {
                            Text("Учебный год \(year)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateTaskSheet = true
                        HapticManager.shared.touchGlass()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(store.theme.preset.primaryAccent)
                    }
                }
            }
            .sheet(item: $selectedTaskForDetail) { task in
                TaskDetailSheet(store: store, task: task)
            }
            .sheet(isPresented: $showCreateTaskSheet) {
                TaskEditView(store: store)
            }
            .sheet(isPresented: $showCreateSubjectSheet) {
                SubjectEditView(store: store)
            }
        }
    }

    // MARK: - Hero Stats Card
    private var heroStatsCard: some View {
        HStack(spacing: 16) {
            // Animated Circular Progress Ring
            GlassProgressRing(
                progress: Double(store.overallProgressPercentage) / 100.0,
                size: 92,
                strokeWidth: 9,
                accentColors: [store.theme.preset.primaryAccent, store.theme.preset.secondaryAccent]
            )

            // Details Column
            VStack(alignment: .leading, spacing: 6) {
                // Priority badges counters
                HStack(spacing: 12) {
                    priorityCounter(label: "Критич.", count: store.criticalCount, color: TaskPriority.critical.color)
                    priorityCounter(label: "Высок.", count: store.highCount, color: TaskPriority.high.color)
                }

                HStack(spacing: 12) {
                    priorityCounter(label: "Средн.", count: store.mediumCount, color: TaskPriority.medium.color)
                    priorityCounter(label: "Низк.", count: store.lowCount, color: TaskPriority.low.color)
                }

                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.vertical, 2)

                // Countdown Timer
                if let sem = store.activeSemester {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 13))
                            .foregroundColor(.cyan)

                        VStack(alignment: .leading, spacing: 0) {
                            Text("До сессии:")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            Text("\(sem.daysRemainingToSession) дн. осталось")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                } else {
                    Text("Семестр не настроен")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(16)
        .liquidGlass(
            cornerRadius: 22,
            depth: store.theme.glassDepth,
            tint: store.theme.preset.primaryAccent,
            specular: true,
            glow: 0.4
        )
    }

    private func priorityCounter(label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .shadow(color: color.opacity(0.8), radius: 2)

            Text("\(label):")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Text("\(count)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    // MARK: - Subject Filter Carousel
    private var subjectFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "Все" chip
                Button {
                    store.selectedSubjectFilter = nil
                    HapticManager.shared.selectionChanged()
                } label: {
                    Text("Все дисциплины")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(store.selectedSubjectFilter == nil ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(store.selectedSubjectFilter == nil ? store.theme.preset.primaryAccent.opacity(0.3) : Color.white.opacity(0.06))
                                .overlay(
                                    Capsule().strokeBorder(
                                        store.selectedSubjectFilter == nil ? store.theme.preset.primaryAccent : Color.white.opacity(0.12),
                                        lineWidth: 1
                                    )
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())

                // Individual Subjects
                ForEach(store.activeSubjects) { sub in
                    let isSelected = store.selectedSubjectFilter == sub.id
                    Button {
                        store.selectedSubjectFilter = isSelected ? nil : sub.id
                        HapticManager.shared.selectionChanged()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: sub.iconName)
                                .font(.system(size: 12))
                            Text(sub.shortCode)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(isSelected ? .white : sub.themeColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? sub.themeColor.opacity(0.4) : Color.white.opacity(0.06))
                                .overlay(
                                    Capsule().strokeBorder(
                                        isSelected ? sub.themeColor : sub.themeColor.opacity(0.3),
                                        lineWidth: 1
                                    )
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Filter Tabs & Search
    private var filterAndSearchBar: some View {
        VStack(spacing: 10) {
            // Search Input
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.4))
                TextField("Поиск по заданиям и темам...", text: $store.searchQuery)
                    .foregroundColor(.white)
                if !store.searchQuery.isEmpty {
                    Button {
                        store.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(10)
            .liquidGlass(cornerRadius: 14, depth: .crystalClear, specular: false, glow: 0)

            // Segmented Status Filters
            HStack(spacing: 6) {
                ForEach(DataStore.TaskFilterTab.allCases) { tab in
                    let isSelected = store.selectedStatusTab == tab
                    Button {
                        store.selectedStatusTab = tab
                        HapticManager.shared.selectionChanged()
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color.white.opacity(0.2) : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(4)
            .background(
                Capsule().fill(Color.white.opacity(0.06))
            )
        }
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 48))
                .foregroundColor(store.theme.preset.primaryAccent.opacity(0.8))

            Text("Список заданий пуст")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Добавьте дисциплины и лабораторные работы через Конструктор, или загрузите готовый демо-семестр.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                Button {
                    showCreateSubjectSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Создать предмет")
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .buttonStyle(GlassButtonStyle(tint: store.theme.preset.primaryAccent, cornerRadius: 14, isProminent: true))

                Button {
                    store.loadSampleData()
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Демо данные")
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .buttonStyle(GlassButtonStyle(tint: Color.cyan.opacity(0.2), cornerRadius: 14))
            }
            .padding(.top, 8)
        }
        .padding(28)
        .liquidGlass(cornerRadius: 24, depth: store.theme.glassDepth)
        .padding(.top, 20)
    }
}
