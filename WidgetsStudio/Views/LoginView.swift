import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isLoggedIn = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                loginHeader

                if isLoggedIn {
                    loggedInView
                } else {
                    loginForm
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
            Text("登录后查看你的个人数据")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
    }

    private var loginForm: some View {
        VStack(spacing: 20) {
            // Apple 登录
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleAppleSignIn(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack {
                VStack { Divider() }
                Text("或使用邮箱")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                VStack { Divider() }
            }

            // 邮箱登录
            VStack(spacing: 12) {
                TextField("邮箱", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                SecureField("密码", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button(action: { Task { await loginWithEmail() } }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("邮箱登录")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(email.isEmpty || password.isEmpty || isLoading)

            HStack(spacing: 4) {
                Text("还没有账号？")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("注册") {
                    // TODO: 接入注册接口
                }
                .font(.caption)
            }
        }
    }

    private var loggedInView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("登录成功")
                .font(.title2)
                .fontWeight(.bold)
            Text("后续这里可以展示用户持仓、自选股等数据")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { isLoggedIn = false }) {
                Text("退出登录")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.top, 40)
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userId = credential.user
                print("Apple 登录成功，userId: \(userId)")
                // TODO: 把 userId + identityToken 发给后端验证
                isLoggedIn = true
            }
        case .failure(let error):
            errorMessage = "Apple 登录失败: \(error.localizedDescription)"
        }
    }

    private func loginWithEmail() async {
        isLoading = true
        errorMessage = nil

        do {
            let token = try await AuthService.login(username: email, password: password)
            print("邮箱登录成功，token: \(token)")
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    LoginView()
}
