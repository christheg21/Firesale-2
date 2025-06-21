import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Combine

// AuthViewModel to manage authentication state
final class AuthViewModel: ObservableObject {
    @Published var user: User? // Fixed from Auth.User to User
    @Published var isLoading = true
    @Published var role: String?
    let authService: AuthService
    private var cancellables = Set<AnyCancellable>()

    init(authService: AuthService = AuthService()) {
        self.authService = authService
        self.user = authService.user
        self.role = authService.role
        self.isLoading = authService.isLoading
        listenAuth()
        if let currentUser = Auth.auth().currentUser {
            self.user = currentUser
            self.fetchRoleAndStoreName(uid: currentUser.uid)
        }
        authService.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.role = self?.authService.role
            }
            .store(in: &cancellables)
    }

    func listenAuth() {
        authService.listenAuthState()
    }

    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        authService.signIn(email: email, password: password) { [weak self] result in
            if case .success = result {
                self?.fetchRoleAndStoreName(uid: self?.authService.user?.uid ?? "")
            }
            completion(result)
        }
    }

    func signUp(email: String, password: String, role: String, address: String, completion: @escaping (Result<Void, Error>) -> Void) {
        authService.signUp(email: email, password: password, role: role, address: address, completion: completion)
    }

    func signOut() {
        authService.signOut()
    }

    private func fetchRoleAndStoreName(uid: String) {
        authService.fetchRoleAndStoreName(uid: uid)
    }
}

// HomePageView to display the main interface
struct HomePageView: View {
    @StateObject private var auth = AuthViewModel()
    @State private var navigationTrigger = UUID()

    var body: some View {
        NavigationView {
            contentView
                .navigationTitle(auth.user == nil || auth.role == nil ? "Welcome to Firesale" : "Dashboard")
                .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
                .toolbar {
                    if auth.user != nil {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                auth.signOut()
                            }) {
                                Text("Logout")
                            }
                        }
                    }
                }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if auth.isLoading {
            ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
        } else if auth.user == nil || auth.role == nil {
            SignInView(viewModel: auth)
                .id(navigationTrigger)
                .onReceive(auth.$role) { newRole in // Fixed from auth.authService.$role
                    if newRole != nil {
                        navigationTrigger = UUID()
                    }
                }
                .onReceive(auth.$user) { newUser in // Fixed from auth.authService.$user
                    if newUser != nil {
                        navigationTrigger = UUID()
                    }
                }
        } else {
            authenticatedView
        }
    }

    @ViewBuilder
    private var authenticatedView: some View {
        if auth.role == "seller" {
            SellerView(auth: auth.authService)
        } else if auth.role == "buyer" {
            BuyerView(auth: auth.authService)
        } else {
            Text("Unknown role: \(auth.role ?? "nil")")
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#if DEBUG
struct HomePageView_Previews: PreviewProvider {
    static var previews: some View {
        HomePageView()
    }
}
#endif
