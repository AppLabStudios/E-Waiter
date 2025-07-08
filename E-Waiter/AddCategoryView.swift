import SwiftUI

struct AddCategoryView: View {
    @ObservedObject var menuManager: MenuManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var categoryName = ""
    @State private var categoryDescription = ""
    @State private var isActive = true
    @State private var isLoading = false
    
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
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue)
                                
                                Text("Add New Category")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Create a new menu category to organize your dishes")
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
                                        
                                        Text(isLoading ? "Saving..." : "Save Category")
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
        
        let category = MenuCategory(
            name: categoryName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: categoryDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            order: menuManager.categories.count,
            isActive: isActive
        )
        
        menuManager.addCategory(name: category.name, description: category.description) { success in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Custom Styles
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .medium))
    }
}

struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 20)
                .fill(configuration.isOn ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

#Preview {
    AddCategoryView(menuManager: MenuManager())
} 