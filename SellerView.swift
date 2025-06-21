import SwiftUI

struct SellerView: View {
    @ObservedObject var auth: AuthService

    var body: some View {
        TabView {
            SellerStoreHomeView(auth: auth)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Store Home")
                }
            
            SellerAddItemView(auth: auth)
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("Add Item")
                }
            
            SellerAnalyticsView() // Assuming no auth needed; adjust if necessary
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Analytics")
                }
            
            StoreResponseView()
                .tabItem {
                    Image(systemName: "envelope.fill")
                    Text("Reservations")
                }
        }
        .tabViewStyle(DefaultTabViewStyle())
        .accentColor(.black)
        .toolbarBackground(.visible, for: .tabBar)
        .onAppear {
            print("SellerView rendered at \(Date()) with user: \(auth.user?.uid ?? "nil"), role: \(auth.role ?? "nil")")
        }
    }
}

#if DEBUG
struct SellerView_Previews: PreviewProvider {
    static var previews: some View {
        SellerView(auth: AuthService())
    }
}
#endif
