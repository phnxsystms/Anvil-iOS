import SwiftUI

struct AuthView: View {
    @StateObject private var authService = AuthService.shared
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo and Title
                    VStack(spacing: 16) {
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Anvil")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("AI-powered development assistant")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Auth Form
                    VStack(spacing: 16) {
                        // Toggle between login/register
                        Picker("Mode", selection: $isLoginMode) {
                            Text("Sign In").tag(true)
                            Text("Sign Up").tag(false)
                        }
                        .pickerStyle(.segmented)
                        
                        // Form fields
                        VStack(spacing: 12) {
                            if !isLoginMode {
                                TextField("Full Name", text: $name)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.words)
                            }
                            
                            TextField("Email", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                            
                            SecureField("Password", text: $password)
                                .textFieldStyle(.roundedBorder)
                            
                            if !isLoginMode {
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textFieldStyle(.roundedBorder)
                                
                                // Password strength indicator
                                if !password.isEmpty {
                                    PasswordStrengthView(password: password)
                                }
                            }
                        }
                        
                        // Submit button
                        Button(action: submitForm) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                }
                                
                                Text(isLoginMode ? "Sign In" : "Create Account")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(!isFormValid || authService.isLoading)
                        
                        // Alternative action
                        Button(action: { isLoginMode.toggle() }) {
                            HStack {
                                Text(isLoginMode ? "Don't have an account?" : "Already have an account?")
                                    .foregroundColor(.secondary)
                                Text(isLoginMode ? "Sign Up" : "Sign In")
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                    
                    // Terms and Privacy
                    VStack(spacing: 8) {
                        Text("By continuing, you agree to our")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Link("Terms of Service", destination: URL(string: "https://anvil.app/terms")!)
                            Text("and")
                            Link("Privacy Policy", destination: URL(string: "https://anvil.app/privacy")!)
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isFormValid: Bool {
        let emailValid = AuthService.isValidEmail(email)
        let passwordValid = AuthService.isValidPassword(password)
        
        if isLoginMode {
            return emailValid && passwordValid
        } else {
            let nameValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let passwordsMatch = password == confirmPassword
            return emailValid && passwordValid && nameValid && passwordsMatch
        }
    }
    
    private func submitForm() {
        let publisher = isLoginMode
            ? authService.login(email: email, password: password)
            : authService.register(email: email, password: password, name: name)
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        alertMessage = error.localizedDescription
                        showingAlert = true
                    }
                },
                receiveValue: { _ in
                    // Success - user will be automatically redirected via ContentView
                }
            )
            .store(in: &authService.cancellables)
    }
}

struct PasswordStrengthView: View {
    let password: String
    
    private var strength: AuthService.PasswordStrength {
        AuthService.passwordStrength(password)
    }
    
    var body: some View {
        HStack {
            Text("Password Strength:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(strength.description)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(colorForStrength)
            
            Spacer()
        }
    }
    
    private var colorForStrength: Color {
        switch strength {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }
}

#Preview {
    AuthView()
}