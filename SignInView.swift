import SwiftUI

struct SignInView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var role = "buyer"
    @State private var address = ""
    private let roles = ["buyer", "seller"]
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isProcessing = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                Picker("Role", selection: $role) {
                    ForEach(roles, id: \.self) { role in
                        Text(role.capitalized)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical)

                if role == "seller" && !isProcessing {
                    TextField("Store Address", text: $address)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .accessibilityLabel("Store Address")
                        .accessibilityHint("Enter your store's physical address")
                }

                Button(action: {
                    isProcessing = true
                    print("Sign In button pressed with email: \(email), password length: \(password.count) at \(Date())")
                    viewModel.signIn(email: email, password: password) { result in
                        isProcessing = false
                        switch result {
                        case .success:
                            print("Sign-in successful, user: \(viewModel.user?.uid ?? "nil"), role: \(viewModel.role ?? "nil") at \(Date())")
                        case .failure(let error):
                            let errorDesc = error.localizedDescription
                            alertMessage = "Sign-in failed: \(errorDesc). Try '123456' or reset password in Firebase Console."
                            showAlert = true
                            print("Sign-in failed: \(errorDesc) at \(Date())")
                        }
                    }
                }) {
                    Text("Sign In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isProcessing ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(email.isEmpty || password.isEmpty || isProcessing)

                Button(action: {
                    isProcessing = true
                    print("Sign Up button pressed with email: \(email), role: \(role), address: \(address) at \(Date())")
                    viewModel.signUp(email: email, password: password, role: role, address: address) { result in
                        isProcessing = false
                        switch result {
                        case .success:
                            print("Sign-up successful at \(Date())")
                            alertMessage = "Sign-up successful! Please sign in."
                            showAlert = true
                        case .failure(let error):
                            alertMessage = "Sign-up failed: \(error.localizedDescription)"
                            showAlert = true
                        }
                    }
                }) {
                    Text("Sign Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isProcessing ? Color.gray : Color.green)
                        .cornerRadius(10)
                }
                .disabled(email.isEmpty || password.isEmpty || (role == "seller" && address.isEmpty && !isProcessing) || isProcessing)
            }
            .padding()
            .navigationTitle("Welcome to Firesale")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}

#if DEBUG
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(viewModel: AuthViewModel())
    }
}
#endif
