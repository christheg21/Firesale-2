import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import CoreLocation

struct SellerAddItemView: View {
    @ObservedObject var auth: AuthService // Use observed object, not state object

    // Form fields
    @State private var itemName = ""
    @State private var originalPriceString = ""
    @State private var discountPriceString = ""
    @State private var quantityString = ""
    @State private var selectedCategory = "FireKitchen"
    @State private var timeLeft = ""
    @State private var address = "" // Replace latitude/longitude with address
    private let categories = ["FireKitchen", "FireClothing", "FireHouse", "Other"]

    // Photo selection
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoImage: Image?
    @State private var imageData: Data?

    // UI state
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var itemNameError: String?
    @State private var originalPriceError: String?
    @State private var discountPriceError: String?
    @State private var quantityError: String?
    @State private var timeLeftError: String?
    @State private var addressError: String?
    @State private var coordinates: CLLocationCoordinate2D? // State for geocoded coordinates
    @State private var isSubmitting = false // Track submission state

    var isFormValid: Bool {
        validateInputs()
        return itemNameError == nil &&
               originalPriceError == nil &&
               discountPriceError == nil &&
               quantityError == nil &&
               timeLeftError == nil &&
               addressError == nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    formSection
                    previewSection
                    submitButton
                }
                .padding(.vertical)
                .overlay {
                    if isSubmitting {
                        ProgressView("Submitting...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
            }
            .navigationTitle("Add New Deal")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .task {
                auth.listenAuthState() // Move to task for async initialization
                if !address.isEmpty {
                    await updateCoordinates()
                }
            }
            .onChange(of: address) { newAddress in
                Task {
                    await updateCoordinates()
                }
            }
        }
    }

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            field("Item Name", text: $itemName, error: $itemNameError)
            field("Original Price (£)", text: $originalPriceString, keyboard: .decimalPad, error: $originalPriceError)
            field("Discount Price (£)", text: $discountPriceString, keyboard: .decimalPad, error: $discountPriceError)
            field("Quantity", text: $quantityString, keyboard: .numberPad, error: $quantityError)
            Text("Store Name: \(auth.storeName ?? "Not set")")
                .font(.body)
                .foregroundColor(.gray)
                .padding(.vertical, 4)
            field("Time Left (e.g., 5 days)", text: $timeLeft, error: $timeLeftError)
            field("Address", text: $address, error: $addressError)

            Picker("Category", selection: $selectedCategory) {
                ForEach(categories, id: \.self) { Text($0) }
            }
            .pickerStyle(.menu)
            .padding(.vertical, 4)

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        .frame(height: 150)
                    if let photoImage = photoImage {
                        photoImage
                            .resizable()
                            .scaledToFill()
                            .frame(height: 150)
                            .clipped()
                            .cornerRadius(10)
                    } else {
                        VStack {
                            Image(systemName: "camera")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("Select Photo")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .onChange(of: selectedPhoto) { _, new in
                Task {
                    if let new = new,
                       let data = try? await new.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        imageData = data
                        photoImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var previewSection: some View {
        if let item = previewItem() {
            VStack(alignment: .leading, spacing: 8) {
                Text("Preview")
                    .font(.headline)
                ItemBoxView(
                    item: item,
                    cartItems: .constant([]),
                    reservedItems: .constant([:]),
                    favoriteItems: .constant([]),
                    bottomText: "",
                    isNavLink: false
                )
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 4)
            .padding(.horizontal)
        } else {
            EmptyView()
        }
    }

    private var submitButton: some View {
        Button(action: submitDeal) {
            Text("Submit Deal")
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isFormValid ? (isSubmitting ? Color.gray : Color.blue) : Color.gray)
                .cornerRadius(10)
        }
        .disabled(!isFormValid || isSubmitting)
        .padding(.horizontal)
    }

    private func field(_ placeholder: String, text: Binding<String>,
                       keyboard: UIKeyboardType = .default, error: Binding<String?>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textFieldStyle(.roundedBorder)
                .onChange(of: text.wrappedValue) { _ in validateInputs() }
            if let msg = error.wrappedValue {
                Text(msg)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private func previewItem() -> Item? {
        guard let originalPrice = Double(originalPriceString),
              let discountPrice = Double(discountPriceString),
              let qty = Int(quantityString),
              let coordinates = coordinates, // Use precomputed coordinates
              let uid = auth.user?.uid,
              let storeName = auth.storeName else { return nil }
        return Item(
            id: nil,
            name: itemName,
            originalPrice: originalPrice,
            discountPrice: discountPrice,
            storeName: storeName,
            timeLeft: timeLeft,
            location: coordinates,
            quantity: qty,
            storeId: uid,
            category: selectedCategory,
            photoUrl: ""
        )
    }

    private func submitDeal() {
        Task {
            isSubmitting = true // Show progress indicator
            do {
                let itemTask = Task<Item?, Error> {
                    do {
                        let coordinates = try await geocodeAddress(address)
                        print("Computed coordinates: \(coordinates)") // Debug log
                        if let originalPrice = Double(originalPriceString),
                           let discountPrice = Double(discountPriceString),
                           let qty = Int(quantityString),
                           let uid = auth.user?.uid,
                           let storeName = auth.storeName {
                            return Item(
                                id: nil,
                                name: itemName,
                                originalPrice: originalPrice,
                                discountPrice: discountPrice,
                                storeName: storeName,
                                timeLeft: timeLeft,
                                location: coordinates,
                                quantity: qty,
                                storeId: uid,
                                category: selectedCategory,
                                photoUrl: ""
                            )
                        }
                        return nil
                    } catch {
                        print("Submit deal error: \(error.localizedDescription)")
                        return nil
                    }
                }
                if let finalItem = try await itemTask.value {
                    guard let uid = auth.user?.uid else {
                        alertMessage = "User not authenticated"
                        showAlert = true
                        return
                    }
                    let db = Firestore.firestore()
                    if let data = imageData {
                        let path = "items/\(uid)/\(Date().timeIntervalSince1970).jpg"
                        let ref = Storage.storage().reference().child(path)
                        try await ref.putDataAsync(data, metadata: nil)
                        let url = try await ref.downloadURL()
                        let newItem = Item(
                            id: finalItem.id,
                            name: finalItem.name,
                            originalPrice: finalItem.originalPrice,
                            discountPrice: finalItem.discountPrice,
                            storeName: finalItem.storeName,
                            timeLeft: finalItem.timeLeft,
                            location: finalItem.location,
                            quantity: finalItem.quantity,
                            storeId: finalItem.storeId,
                            category: finalItem.category,
                            photoUrl: url.absoluteString
                        )
                        saveItem(newItem, to: db.collection("items"))
                    } else {
                        saveItem(finalItem, to: db.collection("items"))
                    }
                } else {
                    alertMessage = "Failed to prepare item for submission"
                    showAlert = true
                }
            } catch {
                alertMessage = "Error submitting deal: \(error.localizedDescription)"
                showAlert = true
            }
            isSubmitting = false // Hide progress indicator
        }
    }

    private func updateCoordinates() async {
        do {
            let coords = try await geocodeAddress(address)
            coordinates = coords
        } catch {
            coordinates = nil
            print("Geocoding error: \(error.localizedDescription)")
        }
    }

    private func saveItem(_ item: Item, to col: CollectionReference) {
        do {
            _ = try col.addDocument(from: item)
            alertMessage = "Deal submitted!"
            clearForm()
        } catch {
            alertMessage = "Error: \(error.localizedDescription)"
        }
        showAlert = true
    }

    private func clearForm() {
        itemName = ""
        originalPriceString = ""
        discountPriceString = ""
        quantityString = ""
        timeLeft = ""
        address = ""
        photoImage = nil
        imageData = nil
        coordinates = nil
    }

    private func validateInputs() {
        itemNameError = itemName.isEmpty ? "Required" : nil
        originalPriceError = Double(originalPriceString) != nil ? nil : "Invalid"
        discountPriceError = Double(discountPriceString) != nil ? nil : "Invalid"
        quantityError = Int(quantityString) != nil ? nil : "Invalid"
        timeLeftError = timeLeft.isEmpty ? "Required" : nil
        addressError = address.isEmpty ? "Required" : nil
    }

    private func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(address)
        guard let placemark = placemarks.first, let location = placemark.location else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to geocode address"])
        }
        return location.coordinate
    }
}

#if DEBUG
struct SellerAddItemView_Previews: PreviewProvider {
    static var previews: some View {
        SellerAddItemView(auth: AuthService())
    }
}
#endif
