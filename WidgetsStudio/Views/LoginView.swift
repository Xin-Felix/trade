import SwiftUI

enum LoginStep {
    case email
    case code(email: String)
}

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    let autoLoginError: String?

    @State private var step: LoginStep = .email
    @State private var email = ""
    @State private var code = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var countdown = 0

    private var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }

    private var isCodeValid: Bool {
        code.count == 6 && code.allSatisfy(\.isNumber)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                loginHeader

                switch step {
                case .email:
                    emailForm
                case .code(let email):
                    codeForm(email: email)
                }
            }
            .padding()
            .navigationTitle("登录")
        }
    }

    private var loginHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)
            Text("Widgets Studio")
                .font(.title)
                .fontWeight(.bold)
            Text("验证码登录，无需密码")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
    }

    private var emailForm: some View {
        VStack(spacing: 20) {
            TextField("邮箱", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            if let autoLoginError {
                Text(autoLoginError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button(action: { Task { await sendCode() } }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("获取验证码")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(!isEmailValid || isLoading)

            Button(action: { Task { await loginWithTestAccount() } }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("测试账号登录")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(isLoading)
        }
    }

    private func codeForm(email: String) -> some View {
        VStack(spacing: 20) {
            Text("验证码已发送至 \(email)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("请输入 6 位验证码", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .multilineTextAlignment(.center)
                .font(.title2)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button(action: { Task { await verifyCode() } }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("登录")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(!isCodeValid || isLoading)

            Button(action: { Task { await resendCode() } }) {
                Text(countdown > 0 ? "重新发送 (\(countdown)s)" : "重新发送")
                    .font(.caption)
            }
            .disabled(countdown > 0 || isLoading)

            Button("换邮箱") {
                withAnimation {
                    step = .email
                    code = ""
                    errorMessage = nil
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func sendCode() async {
        isLoading = true
        errorMessage = nil
        do {
            try await AuthService.sendEmailCode(email: email)
            withAnimation {
                step = .code(email: email)
            }
            startCountdown()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func resendCode() async {
        isLoading = true
        errorMessage = nil
        do {
            try await AuthService.sendEmailCode(email: email)
            startCountdown()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func verifyCode() async {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await AuthService.verifyEmailCode(email: email, code: code)
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loginWithTestAccount() async {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await AuthService.loginWithTestAccount()
            isLoggedIn = true
        } catch {
            errorMessage = "测试登录失败: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func startCountdown() {
        countdown = 60
        Task {
            while countdown > 0 {
                try? await Task.sleep(for: .seconds(1))
                countdown -= 1
            }
        }
    }
}

#Preview {
    LoginView(isLoggedIn: .constant(false), autoLoginError: nil)
}
