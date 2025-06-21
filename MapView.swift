import SwiftUI
import MapKit
import FirebaseFirestore

struct MapView: View {
    let stores: [Store]
    @Binding var cartItems: [Item]
    @Binding var reservedItems: [Item: Date]
    @Binding var favoriteItems: [Item]
    @State private var cameraPosition: MapCameraPosition = {
        let center = CLLocationCoordinate2D(latitude: 51.4946499, longitude: 0.1619471) // Center on your item’s location
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        return .region(MKCoordinateRegion(center: center, span: span))
    }()
    @State private var selectedStore: Store?

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(stores) { store in
                Annotation(store.name, coordinate: store.coordinate) {
                    ZStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                            .font(.title)
                    }
                    .onTapGesture {
                        selectedStore = store
                    }
                }
            }
        }
        .mapStyle(.standard)
        .sheet(item: $selectedStore) { store in
            StorePopupView(
                store: store,
                cartItems: $cartItems,
                reservedItems: $reservedItems,
                favoriteItems: $favoriteItems
            )
            .presentationDetents([.fraction(0.4)]) // Fixed: Correct syntax for 40% height
            .presentationDragIndicator(.visible)   // Now works with valid detents
        }
        .navigationTitle("Firesale Stores")
        .onAppear {
            print("MapView rendered at \(Date())")
        }
    }
}
