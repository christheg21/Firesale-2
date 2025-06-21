import SwiftUI

struct FeaturedBannerView: View {
    let items: [Item]
    @Binding var cartItems: [Item]
    @Binding var reservedItems: [Item: Date]
    @Binding var favoriteItems: [Item]
    @State private var currentIndex = 0
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(items.indices, id: \.self) { index in
                NavigationLink(destination: ItemDetailView(item: items[index], cartItems: $cartItems, reservedItems: $reservedItems, favoriteItems: $favoriteItems)) {
                    ZStack {
                        AsyncImage(url: URL(string: items[index].photoUrl ?? "")) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(10)
                        VStack {
                            Spacer()
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(items[index].name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("\(items[index].discountPercentage)% OFF")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                    Text("£\(String(format: "%.2f", items[index].discountPrice))")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.black.opacity(0.5))
                        }
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .frame(height: 200)
        .onReceive(timer) { _ in
            withAnimation {
                currentIndex = (currentIndex + 1) % items.count
            }
        }
        .onAppear {
            print("FeaturedBannerView rendered at \(Date())")
        }
    }
}
