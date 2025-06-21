import SwiftUI

struct FilterBarView: View {
    @Binding var selectedSort: SortOption  // Existing property for sort selection
    @Binding var isGridView: Bool          // New property to fix the errors

    var body: some View {
        HStack {
            Picker("Sort", selection: $selectedSort) {
                ForEach(SortOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Spacer()
            
            Button(action: {
                isGridView.toggle()  // Line 21: Toggles grid/list view
            }) {
                Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")  // Line 23: Icon based on state
            }
            .accessibilityLabel(isGridView ? "Switch to list view" : "Switch to grid view")  // Line 26: Accessibility
        }
        .padding(.horizontal)
    }
}

// Assuming SortOption is defined elsewhere, e.g.:
// enum SortOption: String, CaseIterable, Identifiable {
//     case newest = "Newest"
//     case priceLow = "Price: Low to High"
//     var id: String { rawValue }
// }
