import SwiftUI

struct StoreInfoView: View {
    let store: Store
    
    var body: some View {
        VStack(spacing: 16) {
            Text(store.name)
                .font(.title2)
                .bold()
                .foregroundColor(.black)
            
            Text("\(String(format: "%.1f", generateRandomDistance())) miles away")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("Rating: ★★★★☆")
                .font(.subheadline)
                .foregroundColor(.yellow)
            
            Button("Close") {
                // Dismiss sheet
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .accessibilityLabel("Close store info")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 4)
        .padding()
    }
}
