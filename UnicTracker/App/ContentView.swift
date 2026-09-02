import SwiftUI

public struct ContentView: View {
    @StateObject private var store = DataStore()
    @State private var showSettings: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            MainTrackerView(store: store, onOpenSettings: {
                showSettings = true
            })
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsHubView(store: store)
        }
    }
}
