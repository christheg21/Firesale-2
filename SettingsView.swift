import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack {
            Text("Settings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            Text("Customize your account preferences (coming soon)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding()
            Spacer()
        }
        .padding()
        .navigationTitle("Settings")
    }
}
