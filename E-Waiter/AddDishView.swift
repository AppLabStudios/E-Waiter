import SwiftUI
import FirebaseStorage
import PhotosUI

struct AddDishView: View {
    @ObservedObject var menuManager: MenuManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var dishName = ""
    @State private var dishDescription = ""
    @State private var price = ""
    @State private var selectedCategoryId = ""
    @State private var isAvailable = true
    @State private var preparationTime = 15
    @State private var selectedAllergens: Set<String> = []
    @State private var isLoading = false
    @State private var selectedImage: UIImage?
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var isImagePickerPresented = false
    @State private var isUploadingImage = false
    
    private let allergens = [
        "Gluten", "Dairy", "Eggs", "Fish", "Shellfish", 
        "Tree Nuts", "Peanuts", "Soy", "Wheat", "Sesame"
    ]
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    backgroundGradient
                    
                    ScrollView {
                        VStack(spacing: 30) {
                            headerView
                            formView
                            actionButtonsView
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
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.05, green: 0.1, blue: 0.15),
                Color(red: 0.1, green: 0.15, blue: 0.2)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Add New Dish")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Create a new dish for your menu")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
    
    // MARK: - Form
    private var formView: some View {
        VStack(spacing: 24) {
            dishImageField
            dishNameField
            dishDescriptionField
            priceField
            categorySelectionField
            preparationTimeField
            allergensField
            availabilityField
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
    }
    
    // MARK: - Form Fields
        private var dishImageField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dish Image")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Button(action: {
                isImagePickerPresented = true
            }) {
                imagePickerButtonContent
            }
        }
        .photosPicker(isPresented: $isImagePickerPresented, selection: $selectedImageItem, matching: .images)
        .onChange(of: selectedImageItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }
    
    private var imagePickerButtonContent: some View {
        HStack {
            imagePreviewSection
            imageInfoSection
            Spacer()
            removeImageButton
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var imagePreviewSection: some View {
        Group {
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Add Photo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(width: 80, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    private var imageInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(selectedImage == nil ? "Tap to add dish image" : "Image selected")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Text(selectedImage == nil ? "Optional" : "Tap to change")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private var removeImageButton: some View {
        Group {
            if selectedImage != nil {
                Button(action: {
                    selectedImage = nil
                    selectedImageItem = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private var dishNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dish Name")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            TextField("e.g., Pasta Carbonara", text: $dishName)
                .textFieldStyle(CustomTextFieldStyle())
                .autocapitalization(.words)
        }
    }
    
    private var dishDescriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            TextField("Describe the dish, ingredients, etc.", text: $dishDescription, axis: .vertical)
                .textFieldStyle(CustomTextFieldStyle())
                .lineLimit(3...6)
        }
    }
    
    private var priceField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Price")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            HStack {
                Text("$")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                TextField("0.00", text: $price)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.decimalPad)
            }
        }
    }
    
    private var categorySelectionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            if menuManager.categories.isEmpty {
                noCategoriesView
            } else {
                categoryMenuView
            }
        }
    }
    
    private var noCategoriesView: some View {
        Text("No categories available. Please create a category first.")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.7))
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
    }
    
    private var categoryMenuView: some View {
        Menu {
            ForEach(menuManager.categories.filter { $0.isActive }) { category in
                Button(category.name) {
                    selectedCategoryId = category.id
                }
            }
        } label: {
            HStack {
                Text(selectedCategoryId.isEmpty ? "Select Category" : menuManager.getCategoryById(selectedCategoryId)?.name ?? "Select Category")
                    .foregroundColor(selectedCategoryId.isEmpty ? .white.opacity(0.5) : .white)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    private var preparationTimeField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preparation Time")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            HStack {
                Text("\(preparationTime) minutes")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Slider(value: Binding(
                    get: { Double(preparationTime) },
                    set: { preparationTime = Int($0) }
                ), in: 5...60, step: 5)
                .accentColor(.orange)
            }
        }
    }
    
    private var allergensField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Allergens (Optional)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(allergens, id: \.self) { allergen in
                    AllergenButton(
                        allergen: allergen,
                        isSelected: selectedAllergens.contains(allergen),
                        onTap: {
                            if selectedAllergens.contains(allergen) {
                                selectedAllergens.remove(allergen)
                            } else {
                                selectedAllergens.insert(allergen)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var availabilityField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            HStack {
                Toggle("Available", isOn: $isAvailable)
                    .toggleStyle(CustomToggleStyle())
                
                Spacer()
                
                Text(isAvailable ? "Visible to customers" : "Hidden from customers")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            Button(action: saveDish) {
                HStack {
                    if isLoading || isUploadingImage {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                    }
                    
                    Text(isLoading ? (isUploadingImage ? "Uploading Image..." : "Saving...") : "Save Dish")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(canSave ? Color.orange : Color.gray.opacity(0.3))
                )
            }
            .disabled(!canSave || isLoading || isUploadingImage)
            
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    // MARK: - Helper Methods
    private var canSave: Bool {
        !dishName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedCategoryId.isEmpty &&
        !price.isEmpty &&
        Double(price) != nil &&
        Double(price)! > 0
    }
    
    private func uploadImage(completion: @escaping (String?) -> Void) {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(nil)
            return
        }
        
        isUploadingImage = true
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageName = "dishes/\(UUID().uuidString).jpg"
        let imageRef = storageRef.child(imageName)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { metadata, error in
            DispatchQueue.main.async {
                self.isUploadingImage = false
                
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                imageRef.downloadURL { url, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("Error getting download URL: \(error.localizedDescription)")
                            completion(nil)
                        } else {
                            completion(url?.absoluteString)
                        }
                    }
                }
            }
        }
    }
    
    private func saveDish() {
        guard canSave else { return }
        
        isLoading = true
        
        guard let priceValue = Double(price),
              let category = menuManager.getCategoryById(selectedCategoryId) else {
            isLoading = false
            return
        }
        
        // If there's an image to upload, do that first
        if selectedImage != nil {
            uploadImage { imageURL in
                self.createDishWithImageURL(imageURL)
            }
        } else {
            createDishWithImageURL(nil)
        }
    }
    
    private func createDishWithImageURL(_ imageURL: String?) {
        guard let priceValue = Double(price),
              let category = menuManager.getCategoryById(selectedCategoryId) else {
            isLoading = false
            return
        }
        
        let dish = MenuDish(
            name: dishName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: dishDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            price: priceValue,
            categoryId: selectedCategoryId,
            categoryName: category.name,
            imageURL: imageURL,
            isAvailable: isAvailable,
            allergens: Array(selectedAllergens),
            preparationTime: preparationTime
        )
        
        menuManager.addDish(dish) { success in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.dismiss()
                }
            }
        }
    }
}

// MARK: - Allergen Button Component
struct AllergenButton: View {
    let allergen: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .green : .white.opacity(0.5))
                
                Text(allergen)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.green.opacity(0.1) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.green.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    AddDishView(menuManager: MenuManager())
} 