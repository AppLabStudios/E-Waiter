import SwiftUI

struct EditCategoryView: View {
    @ObservedObject var menuManager: MenuManager
    @Environment(\.dismiss) private var dismiss
    
    let category: MenuCategory
    
    @State private var categoryName: String
    @State private var categoryDescription: String
    @State private var isActive: Bool
    @State private var isLoading = false
    
    init(menuManager: MenuManager, category: MenuCategory) {
        self.menuManager = menuManager
        self.category = category
        self._categoryName = State(initialValue: category.name)
        self._categoryDescription = State(initialValue: category.description)
        self._isActive = State(initialValue: category.isActive)
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Background gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.05, green: 0.1, blue: 0.15),
                            Color(red: 0.1, green: 0.15, blue: 0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 30) {
                            // Header
                            VStack(spacing: 16) {
                                Image(systemName: "folder.badge.gearshape")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue)
                                
                                Text("Edit Category")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Update your menu category information")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 40)
                            
                            // Form
                            VStack(spacing: 24) {
                                // Category Name
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Category Name")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    TextField("e.g., Main Course, Desserts, Drinks", text: $categoryName)
                                        .textFieldStyle(CustomTextFieldStyle())
                                        .autocapitalization(.words)
                                }
                                
                                // Category Description
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Description (Optional)")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    TextField("Brief description of this category", text: $categoryDescription, axis: .vertical)
                                        .textFieldStyle(CustomTextFieldStyle())
                                        .lineLimit(3...6)
                                }
                                
                                // Active Status
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Status")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    HStack {
                                        Toggle("Active", isOn: $isActive)
                                            .toggleStyle(CustomToggleStyle())
                                        
                                        Spacer()
                                        
                                        Text(isActive ? "Visible to customers" : "Hidden from customers")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            
                            // Action Buttons
                            VStack(spacing: 16) {
                                Button(action: saveCategory) {
                                    HStack {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 18, weight: .medium))
                                        }
                                        
                                        Text(isLoading ? "Saving..." : "Save Changes")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(categoryName.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                                    )
                                }
                                .disabled(categoryName.isEmpty || isLoading)
                                
                                Button(action: {
                                    dismiss()
                                }) {
                                    Text("Cancel")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: .constant(!menuManager.errorMessage.isEmpty)) {
            Button("OK") {
                menuManager.errorMessage = ""
            }
        } message: {
            Text(menuManager.errorMessage)
        }
    }
    
    private func saveCategory() {
        guard !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isLoading = true
        
        let updatedCategory = MenuCategory(
            id: category.id,
            name: categoryName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: categoryDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            order: category.order,
            isActive: isActive,
            createdAt: category.createdAt
        )
        
        menuManager.updateCategory(updatedCategory) { success in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    EditCategoryView(
        menuManager: MenuManager(),
        category: MenuCategory(name: "Test Category", description: "Test Description")
    )
} 