import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationScheduler.self) private var notificationScheduler
    @Environment(HealthKitManager.self) private var healthKitManager

    @AppStorage("selectedTheme") private var selectedThemeName: String = AppTheme.synthwave.rawValue
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("followUpDelayMinutes") private var followUpDelayMinutes = 30

    @Query(filter: #Predicate<Medication> { $0.isActive })
    private var medications: [Medication]

    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            Form {
                themeSection
                notificationSection
                healthKitSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("settings")
        .navigationBarTitleDisplayMode(.large)
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationAuthStatus = settings.authorizationStatus
        }
    }

    // MARK: - Theme

    private var themeSection: some View {
        Section("Appearance") {
            VStack(spacing: 12) {
                ForEach(AppTheme.allCases, id: \.self) { t in
                    themeCard(t)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(theme.surface)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    private func themeCard(_ t: AppTheme) -> some View {
        let isSelected = selectedThemeName == t.rawValue
        return Button {
            selectedThemeName = t.rawValue
            Haptics.tap()
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(t.background)
                    .frame(width: 44, height: 44)
                    .overlay(
                        HStack(spacing: 4) {
                            Circle().fill(t.primary).frame(width: 10, height: 10)
                            Circle().fill(t.secondary).frame(width: 8, height: 8)
                            Circle().fill(t.accent).frame(width: 6, height: 6)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(t.displayName)
                        .font(.themeBody(theme))
                        .foregroundStyle(theme.textPrimary)
                    Text(t.tagline)
                        .font(.themeCaption(theme))
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.primary)
                }
            }
            .padding(10)
            .background(isSelected ? theme.primary.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notifications

    private var notificationSection: some View {
        Section("Notifications") {
            Toggle("Enable Reminders", isOn: $notificationsEnabled)
                .tint(theme.primary)
                .font(.themeBody(theme))
                .onChange(of: notificationsEnabled) { _, enabled in
                    if enabled {
                        notificationScheduler.scheduleAll(medications: medications)
                    } else {
                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    }
                }

            if notificationsEnabled {
                Picker("Follow-up reminder", selection: $followUpDelayMinutes) {
                    Text("None").tag(0)
                    Text("15 min").tag(15)
                    Text("30 min").tag(30)
                    Text("1 hour").tag(60)
                }
                .font(.themeBody(theme))
            }

            HStack {
                Image(systemName: notificationAuthStatus == .authorized ? "bell.fill" : "bell.slash.fill")
                    .foregroundStyle(notificationAuthStatus == .authorized ? theme.success : theme.primary)
                Text(notificationStatusText)
                    .font(.themeCaption(theme))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .listRowBackground(theme.surface)
    }

    private var notificationStatusText: String {
        switch notificationAuthStatus {
        case .authorized: return "Notifications are allowed"
        case .denied: return "Notifications are blocked — open Settings to fix this"
        case .provisional: return "Notifications in quiet delivery mode"
        default: return "Notification permission not yet requested"
        }
    }

    // MARK: - HealthKit

    private var healthKitSection: some View {
        Section("Health") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Optional: sync your dose logs to Apple Health. Useful if your doctor wants data. No weird tracking.")
                    .font(.themeCaption(theme))
                    .foregroundStyle(theme.textSecondary)

                HStack {
                    Image(systemName: healthKitManager.isConnected ? "heart.fill" : "heart")
                        .foregroundStyle(healthKitManager.isConnected ? theme.success : theme.textSecondary)
                    Text(healthKitManager.statusDescription)
                        .font(.themeBody(theme))
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    if !healthKitManager.isConnected && HealthKitAvailability.isAvailable {
                        Button("Connect") {
                            Task { await healthKitManager.requestPermission() }
                        }
                        .font(.themeCaption(theme))
                        .foregroundStyle(theme.primary)
                    }
                }
            }
        }
        .listRowBackground(theme.surface)
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                    .font(.themeBody(theme))
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .font(.themeCaption(theme))
                    .foregroundStyle(theme.textSecondary)
            }

            Text(theme.tagline)
                .font(.themeCaption(theme))
                .foregroundStyle(theme.textSecondary)
                .italic()

            Text("GenRx is not a medical device and does not provide medical advice.")
                .font(.themeCaption(theme))
                .foregroundStyle(theme.textSecondary)
        }
        .listRowBackground(theme.surface)
    }
}
