import SwiftUI

struct HealthKitOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Environment(HealthKitManager.self) private var healthKitManager

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 60))
                        .foregroundStyle(theme.primary)
                        .padding(.top, 32)

                    VStack(spacing: 8) {
                        Text("Apple Health")
                            .font(.themeHeadline(theme))
                            .foregroundStyle(theme.textPrimary)

                        Text("Optional: sync your dose logs to Apple Health. Useful if your doctor wants data. No weird tracking.")
                            .font(.themeBody(theme))
                            .foregroundStyle(theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    VStack(spacing: 12) {
                        if HealthKitAvailability.isAvailable {
                            Button {
                                Task {
                                    await healthKitManager.requestPermission()
                                    dismiss()
                                }
                            } label: {
                                Text("Connect to Apple Health")
                                    .font(.themeBody(theme))
                                    .foregroundStyle(theme.background)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(theme.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius))
                            }
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Not now")
                                .font(.themeBody(theme))
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
