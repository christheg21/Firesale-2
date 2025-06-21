import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FindFriendsView: View {
    @State private var usernameToAdd = ""
    @Binding var followingCount: Int
    @State private var showAlert = false
    @State private var alertMessage = ""
    private let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 20) {
            Text("Find Friends")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.black)
            
            TextField("Enter username", text: $usernameToAdd)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .foregroundColor(.black)
                .accessibilityLabel("Enter username to add")
                .accessibilityHint("Type the username of the friend you want to follow")
            
            Button(action: {
                addFriend()
            }) {
                Text("Add as Following")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .accessibilityLabel("Add as Following")
            .accessibilityHint("Adds the entered username to your following list")
            
            Spacer()
        }
        .padding()
        .navigationTitle("Find Friends")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Message"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            print("FindFriendsView rendered at \(Date())")
        }
    }

    private func addFriend() {
        guard !usernameToAdd.isEmpty else {
            alertMessage = "Please enter a username."
            showAlert = true
            return
        }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        // Placeholder: Save to Firestore (e.g., in a "following" collection)
        db.collection("users").document(userId).updateData([
            "following": FieldValue.arrayUnion([usernameToAdd])
        ]) { error in
            if let error = error {
                alertMessage = "Error adding friend: \(error.localizedDescription)"
                showAlert = true
                print("Error adding friend: \(error)")
            } else {
                followingCount += 1
                alertMessage = "\(usernameToAdd) has been added to your following!"
                showAlert = true
                usernameToAdd = ""
                print("Added \(usernameToAdd) to following")
            }
        }
    }
}
