import SwiftUI
import AuthenticationServices

/// Presents a login/register screen when not authenticated.
/// Wraps the main content and shows it only when authenticated.
struct AuthGateView<Content: View>: View {
    @Environment(AuthManager.self) private var authManager
    @ViewBuilder let content: () -> Content

    var body: some View {
        if authManager.isAuthenticated {
            content()
        } else {
            LoginView()
        }
    }
}

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var isRegistering = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo / branding
            VStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

                Text("Mentat")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your AI-Powered Second Brain")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Form
            VStack(spacing: 16) {
                if isRegistering {
                    TextField("Display Name", text: $displayName)
                        .textContentType(.name)
                        .textFieldStyle(.roundedBorder)
                }

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $password)
                    .textContentType(isRegistering ? .newPassword : .password)
                    .textFieldStyle(.roundedBorder)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    submit()
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(isRegistering ? "Create Account" : "Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(email.isEmpty || password.isEmpty || isLoading)

                Button(isRegistering ? "Already have an account? Sign In" : "Don't have an account? Register") {
                    isRegistering.toggle()
                    errorMessage = nil
                }
                .font(.subheadline)
            }
            .frame(maxWidth: 360)

            // Sign in with Apple
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let authorization):
                    Task {
                        isLoading = true
                        defer { isLoading = false }
                        do {
                            try await authManager.signInWithApple(authorization: authorization)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(maxWidth: 360, minHeight: 50)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private func submit() {
        isLoading = true
        errorMessage = nil
        Task {
            defer { isLoading = false }
            do {
                if isRegistering {
                    let name = displayName.isEmpty ? email.components(separatedBy: "@").first ?? "User" : displayName
                    try await authManager.register(email: email, password: password, displayName: name)
                } else {
                    try await authManager.login(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
