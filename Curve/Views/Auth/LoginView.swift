import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var auth = AuthManager.shared
    var onSignedIn: () -> Void = {}

    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSignUp = false
    @State private var showingForgotPassword = false
    @State private var resetEmail = ""
    @State private var resetConfirmation: String?

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty && !isLoading
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CurveBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 38, height: 38)
                                .glassCard(cornerRadius: 19, padding: 0)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Welcome back")
                                .font(.system(size: 26, weight: .heavy))
                                .foregroundStyle(.white)
                            Text("Log in to keep your streak going.")
                                .font(.curveEyebrow(14))
                                .foregroundStyle(CurveTheme.textSecondary)
                        }
                        .padding(.top, 26)

                        VStack(spacing: 14) {
                            AuthFieldView(label: "Email", text: $email, isSecure: false, isPasswordVisible: .constant(true), keyboardType: .emailAddress)
                            AuthFieldView(label: "Password", text: $password, isSecure: true, isPasswordVisible: $isPasswordVisible)

                            Button {
                                resetEmail = email
                                showingForgotPassword = true
                            } label: {
                                Text("Forgot password?")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.65))
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(Color(red: 0.941, green: 0.718, blue: 0.659))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Button {
                                logIn()
                            } label: {
                                if isLoading {
                                    ProgressView()
                                        .tint(Color(red: 0.078, green: 0.129, blue: 0.114))
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Text("Log in")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.curveChrome)
                            .disabled(!canSubmit)
                            .opacity(canSubmit ? 1 : 0.6)
                        }
                        .padding(.top, 32)

                        HStack(spacing: 12) {
                            Rectangle().fill(.white.opacity(0.25)).frame(height: 1)
                            Text("OR CONTINUE WITH")
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundStyle(CurveTheme.textSecondary)
                                .fixedSize()
                            Rectangle().fill(.white.opacity(0.25)).frame(height: 1)
                        }
                        .padding(.top, 26)

                        Button {
                            signInWithGoogle()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "g.circle.fill")
                                Text("Continue with Google")
                                    .font(.system(size: 13.5, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .glassCard(cornerRadius: 16, padding: 0)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 18)

                        Spacer(minLength: 40)

                        Button {
                            showingSignUp = true
                        } label: {
                            (Text("Don't have an account? ")
                                .foregroundStyle(CurveTheme.textSecondary)
                                + Text("Sign up").bold().foregroundStyle(.white))
                                .font(.system(size: 12.5))
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingSignUp) {
                SignUpView(auth: auth, onSignedIn: onSignedIn)
            }
            .alert("Reset your password", isPresented: $showingForgotPassword) {
                TextField("Email", text: $resetEmail)
                    .textInputAutocapitalization(.never)
                Button("Send reset link") { sendPasswordReset() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("We'll email you a link to reset your password.")
            }
            .alert("Check your email", isPresented: Binding(get: { resetConfirmation != nil }, set: { if !$0 { resetConfirmation = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resetConfirmation ?? "")
            }
        }
        .preferredColorScheme(.dark)
    }

    private func logIn() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                try await auth.logIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
                await SyncManager.pullAll(context: context)
                await MainActor.run {
                    isLoading = false
                    onSignedIn()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func signInWithGoogle() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                try await auth.signInWithGoogle()
                await SyncManager.pullAll(context: context)
                await MainActor.run {
                    isLoading = false
                    onSignedIn()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func sendPasswordReset() {
        Task {
            do {
                try await auth.sendPasswordReset(email: resetEmail.trimmingCharacters(in: .whitespaces))
                await MainActor.run {
                    resetConfirmation = "If an account exists for \(resetEmail), a reset link is on its way."
                }
            } catch {
                await MainActor.run {
                    resetConfirmation = error.localizedDescription
                }
            }
        }
    }
}

/// Shared glass text field used by both Login and Sign Up — a floating
/// uppercase label above the value, matching the design reference's field
/// styling, with a working show/hide toggle for password fields.
struct AuthFieldView: View {
    let label: String
    @Binding var text: String
    var isSecure: Bool = false
    @Binding var isPasswordVisible: Bool
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(CurveTheme.textSecondary)

            HStack {
                Group {
                    if isSecure && !isPasswordVisible {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                            .keyboardType(keyboardType)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .tint(.white)

                if isSecure {
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassCard(cornerRadius: 16, padding: 0)
    }
}

#Preview {
    LoginView()
        .modelContainer(PreviewData.container)
}
