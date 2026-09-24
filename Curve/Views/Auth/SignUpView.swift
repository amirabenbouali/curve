import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var auth = AuthManager.shared
    var onSignedIn: () -> Void = {}

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmVisible = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingLogin = false

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty
            && password.count >= 6
            && password == confirmPassword
            && !isLoading
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
                            Text("Create your account")
                                .font(.system(size: 26, weight: .heavy))
                                .foregroundStyle(.white)
                            Text("Your data follows you across devices from here on.")
                                .font(.curveEyebrow(14))
                                .foregroundStyle(CurveTheme.textSecondary)
                        }
                        .padding(.top, 26)

                        VStack(spacing: 14) {
                            AuthFieldView(label: "Email", text: $email, isSecure: false, isPasswordVisible: .constant(true), keyboardType: .emailAddress)
                            AuthFieldView(label: "Password", text: $password, isSecure: true, isPasswordVisible: $isPasswordVisible)
                            AuthFieldView(label: "Confirm password", text: $confirmPassword, isSecure: true, isPasswordVisible: $isConfirmVisible)

                            if !password.isEmpty && password.count < 6 {
                                Text("Password must be at least 6 characters.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(CurveTheme.textTertiary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else if !confirmPassword.isEmpty && password != confirmPassword {
                                Text("Passwords don't match.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(red: 0.941, green: 0.718, blue: 0.659))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(Color(red: 0.941, green: 0.718, blue: 0.659))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Button {
                                signUp()
                            } label: {
                                if isLoading {
                                    ProgressView()
                                        .tint(Color(red: 0.078, green: 0.129, blue: 0.114))
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Text("Sign up")
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
                            showingLogin = true
                        } label: {
                            (Text("Already have an account? ")
                                .foregroundStyle(CurveTheme.textSecondary)
                                + Text("Log in").bold().foregroundStyle(.white))
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
            .sheet(isPresented: $showingLogin) {
                LoginView(auth: auth, onSignedIn: onSignedIn)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func signUp() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                try await auth.signUp(email: email.trimmingCharacters(in: .whitespaces), password: password)
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
}

#Preview {
    SignUpView()
        .modelContainer(PreviewData.container)
}
