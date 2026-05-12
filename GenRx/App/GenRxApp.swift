import SwiftUI
import SwiftData

@main
struct GenRxApp: App {
    @AppStorage("selectedTheme") private var selectedThemeName: String = AppTheme.synthwave.rawValue
    @AppStorage("hasRequestedHealthKit") private var hasRequestedHealthKit = false

    @Environment(\.scenePhase) private var scenePhase

    private let modelContainer: ModelContainer = {
        let schema = Schema([Medication.self, DoseLog.self])
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        }
        #endif
        return try! ModelContainer(for: schema)
    }()

    @State private var notificationScheduler = NotificationScheduler()
    @State private var healthKitManager = HealthKitManager()
    @State private var showHealthKitSheet = false

    private var currentTheme: AppTheme {
        AppTheme(rawValue: selectedThemeName) ?? .synthwave
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(modelContainer)
                .environment(\.appTheme, currentTheme)
                .environment(notificationScheduler)
                .environment(healthKitManager)
                .modifier(ThemeProvider(theme: currentTheme))
                .sheet(isPresented: $showHealthKitSheet) {
                    HealthKitOnboardingView()
                        .environment(healthKitManager)
                }
                .task {
                    await notificationScheduler.requestPermission()
                    if !hasRequestedHealthKit {
                        showHealthKitSheet = true
                        hasRequestedHealthKit = true
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task {
                            await notificationScheduler.auditAndReschedule(modelContainer: modelContainer)
                        }
                    }
                }
        }
    }
}
