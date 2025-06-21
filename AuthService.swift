import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthService: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var role: String?
    @Published var isLoading = false
    @Published var storeName: String? // Already added

    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        print("AuthService initialized at \(Date()) with objectID: \(Unmanaged.passUnretained(self).toOpaque())")
        Auth.auth().addStateDidChangeListener { [weak self] _, _ in
            self?.syncAuthState()
        }
        syncAuthState()
    }

    private func syncAuthState() {
        Auth.auth().currentUser?.reload(completion: { [weak self] error in
            if let error = error {
                print("Error reloading user: \(error.localizedDescription) at \(Date())")
            }
            DispatchQueue.main.async {
                if let currentUser = Auth.auth().currentUser {
                    print("Initial auth state: user = \(currentUser.uid) at \(Date())")
                    self?.user = currentUser
                    self?.fetchRoleAndStoreName(uid: currentUser.uid)
                } else {
                    print("Initial auth state: no user at \(Date())")
                    self?.user = nil
                    self?.role = nil
                    self?.storeName = nil
                }
            }
        })
    }

    func listenAuthState() {
        print("listenAuthState started at \(Date())")
        isLoading = true
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            print("Auth state changed: user = \(user?.uid ?? "nil") at \(Date())")
            DispatchQueue.main.async {
                self.user = user
                if let uid = user?.uid {
                    self.fetchRoleAndStoreName(uid: uid)
                } else {
                    print("No user authenticated, setting role to nil and isLoading to false at \(Date())")
                    self.role = nil
                    self.isLoading = false
                    self.storeName = nil
                }
            }
        }
    }

    func fetchRoleAndStoreName(uid: String, retryCount: Int = 2) {
        print("Fetching role and store name for uid: \(uid) at \(Date()), retry: \(retryCount)")
        let ref = Firestore.firestore().collection("users").document(uid)
        ref.getDocument { [weak self] snap, err in
            guard let self = self else { return }
            if let err = err {
                print("Firestore error fetching role for uid \(uid): \(err.localizedDescription) (Code: \((err as NSError).code)) at \(Date())")
                if retryCount > 0 && (err as NSError).code == -1005 {
                    print("Retrying fetchRole for uid \(uid) due to network error")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.fetchRoleAndStoreName(uid: uid, retryCount: retryCount - 1)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.role = "buyer"
                        self.isLoading = false
                        self.objectWillChange.send()
                    }
                }
                return
            }
            if let snap = snap {
                let data = snap.data() ?? [:]
                print("Fetched document for uid \(uid): \(data) at \(Date())")
                if snap.exists {
                    if let role = data["role"] as? String {
                        print("Directly fetched role for uid \(uid): \(role) at \(Date())")
                        DispatchQueue.main.async {
                            self.role = role
                            self.storeName = data["storeName"] as? String ?? (data["address"] as? String ?? "")
                            self.isLoading = false
                            self.objectWillChange.send() // Force UI update
                        }
                    } else {
                        print("No 'role' field in document for uid \(uid) at \(Date())")
                        DispatchQueue.main.async {
                            self.role = "buyer"
                            self.storeName = data["storeName"] as? String ?? (data["address"] as? String ?? "")
                            self.isLoading = false
                            self.objectWillChange.send()
                        }
                    }
                } else {
                    print("No user document exists for uid \(uid) at \(Date())")
                    DispatchQueue.main.async {
                        self.role = "buyer"
                        self.storeName = nil
                        self.isLoading = false
                        self.objectWillChange.send()
                    }
                }
            } else {
                print("No snapshot returned for uid \(uid) at \(Date())")
                DispatchQueue.main.async {
                    self.role = "buyer"
                    self.storeName = nil
                    self.isLoading = false
                    self.objectWillChange.send()
                }
            }
            print("fetchRole completed for uid \(uid), role set to: \(self.role ?? "nil"), storeName: \(self.storeName ?? "nil") at \(Date())")
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        print("Signing in with email: \(email), password length: \(password.count) at \(Date())")
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, err in
            guard let self = self else { return }
            if let err = err {
                print("Sign-in error: \(err.localizedDescription) (Code: \((err as NSError).code)) at \(Date()), Details: \(String(describing: err))")
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(.failure(err))
                }
                return
            }
            guard let user = result?.user else {
                print("No user returned at \(Date())")
                DispatchQueue.main.async {
                    self.isLoading = false
                    let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user returned"])
                    completion(.failure(error))
                }
                return
            }
            print("Sign-in successful: \(user.uid) at \(Date())")
            DispatchQueue.main.async {
                self.user = user
                self.fetchRoleAndStoreName(uid: user.uid)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.objectWillChange.send()
                    completion(.success(()))
                }
            }
        }
    }

    func signUp(email: String, password: String, role: String, address: String, completion: @escaping (Result<Void, Error>) -> Void) {
        print("Signing up with email: \(email), role: \(role), address: \(address) at \(Date())")
        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, err in
            guard let self = self else { return }
            if let err = err {
                print("Sign-up error: \(err.localizedDescription) at \(Date())")
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(.failure(err))
                }
                return
            }
            guard let uid = result?.user.uid else {
                print("No uid after sign-up at \(Date())")
                DispatchQueue.main.async {
                    self.isLoading = false
                    let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user ID returned"])
                    completion(.failure(error))
                }
                return
            }
            let data: [String: Any] = [
                "email": email,
                "role": role,
                "address": role == "seller" ? address : ""
            ]
            print("Saving user data for uid \(uid): \(data) at \(Date())")
            Firestore.firestore().collection("users")
                .document(uid)
                .setData(data) { err in
                    if let err = err {
                        print("Error saving user data: \(err.localizedDescription) at \(Date())")
                        DispatchQueue.main.async {
                            self.isLoading = false
                            completion(.failure(err))
                        }
                    } else {
                        print("User data saved for uid \(uid) at \(Date())")
                        DispatchQueue.main.async {
                            self.user = result?.user
                            self.role = role
                            self.storeName = role == "seller" ? address : nil
                            self.isLoading = false
                            self.objectWillChange.send()
                            completion(.success(()))
                        }
                    }
                }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async { [weak self] in
                self?.user = nil
                self?.role = nil
                self?.storeName = nil
                self?.isLoading = false
                print("Signed out successfully at \(Date())")
            }
        } catch {
            print("Sign-out error: \(error.localizedDescription) at \(Date())")
        }
    }
}

struct UserRole: Codable {
    let email: String
    let role: String
    let address: String
}
