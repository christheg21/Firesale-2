import SwiftUI

struct LoginView: View {
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
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never) // Fix: Modern API
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                Picker("Role", selection: $role) {
                    ForEach(roles, id: \.self) { Text($0.capitalized) }
                }
                .pickerStyle(.segmented)

                if role == "seller" {
                    TextField("Store Address", text: $address)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .accessibilityLabel("Store Address")
                        .accessibilityHint("Enter your store address for location")
                }

                Button("Sign In") {
                    isProcessing = true
                    viewModel.signIn(email: email, password: password) { result in // Fix: Line 41
                        isProcessing = false
                        switch result {
                        case .success:
                            print("Sign-in successful at \(Date())")
                        case .failure(let error):
                            alertMessage = error.localizedDescription
                            showAlert = true
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(email.isEmpty || password.isEmpty || isProcessing)

                Button("Sign Up") {
                    isProcessing = true
                    viewModel.signUp(email: email, password: password, role: role, address: address) { result in // Fix: Line 47
                        isProcessing = false
                        switch result {
                        case .success:
                            print("Sign-up successful at \(Date())")
                        case .failure(let error):
                            alertMessage = error.localizedDescription
                            showAlert = true
                        }
                    }
                }
                .buttonStyle(.bordered)
                .disabled(email.isEmpty || password.isEmpty || isProcessing)

                NavigationLink("Go to Sign Up", destination: SignInView(viewModel: viewModel))
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            .padding()
            .navigationTitle("Welcome")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: AuthViewModel())
    }
}
#endif
