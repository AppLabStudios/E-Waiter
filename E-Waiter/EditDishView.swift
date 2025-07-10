import SwiftUI
import FirebaseStorage
import PhotosUI

struct EditDishView: View {
    @ObservedObject var menuManager: MenuManager
    @Environment(\.dismiss) private var dismiss
    
    let dish: MenuDish
    
    @State private var dishName: String
    @State private var dishDescription: String
    @State private var price: String
    @State private var selectedCategoryId: String
    @State private var isAvailable: Bool
    @State private var preparationTime: Int
    @State private var selectedAllergens: Set<String>
    @State private var isLoading = false
    @State private var selectedImage: UIImage?
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var isImagePickerPresented = false
    @State private var isUploadingImage = false
    @State private var showImagePicker = false
    @State private var currentImageURL: String?
    
    private let allergens = [
        "Gluten", "Dairy", "Eggs", "Fish", "Shellfish", 
        "Tree Nuts", "Peanuts", "Soy", "Wheat", "Sesame"
    ]
    
    init(menuManager: MenuManager, dish: MenuDish) {
        self.menuManager = menuManager
        self.dish = dish
        self._dishName = State(initialValue: dish.name)
        self._dishDescription = State(initialValue: dish.description)
        self._price = State(initialValue: String(format: "%.2f", dish.price))
        self._selectedCategoryId = State(initialValue: dish.categoryId)
        self._isAvailable = State(initialValue: dish.isAvailable)
        self._preparationTime = State(initialValue: dish.preparationTime)
        self._selectedAllergens = State(initialValue: Set(dish.allergens))
        self._currentImageURL = State(initialValue: dish.imageURL)
    }
    
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
        .photosPicker(isPresented: $showImagePicker, selection: $selectedImageItem, matching: .images)
        .onChange(of: selectedImageItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
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
            
            Text("Edit Dish")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Update your dish information")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
    
    // MARK: - Form
    private var formView: some View {
        VStack(spacing: 24) {
            // Dish Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Dish Name")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                TextField("Enter dish name", text: $dishName)
                    .textFieldStyle(CustomTextFieldStyle())
                    .autocapitalization(.words)
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                TextField("Describe your dish", text: $dishDescription, axis: .vertical)
                    .textFieldStyle(CustomTextFieldStyle())
                    .lineLimit(3...6)
            }
            
            // Price
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
            
            // Category Selection
            categorySelectionField
            
            // Image Selection
            imageSelectionField
            
            // Preparation Time
            VStack(alignment: .leading, spacing: 8) {
                Text("Preparation Time (minutes)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack {
                    Slider(value: Binding(
                        get: { Double(preparationTime) },
                        set: { preparationTime = Int($0) }
                    ), in: 5...60, step: 5)
                    .accentColor(.orange)
                    
                    Text("\(preparationTime) min")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 60)
                }
            }
            
            // Allergens
            VStack(alignment: .leading, spacing: 12) {
                Text("Allergens")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(allergens, id: \.self) { allergen in
                        AllergenButton(
                            allergen: allergen,
                            isSelected: selectedAllergens.contains(allergen)
                        ) {
                            if selectedAllergens.contains(allergen) {
                                selectedAllergens.remove(allergen)
                            } else {
                                selectedAllergens.insert(allergen)
                            }
                        }
                    }
                }
            }
            
            // Availability
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
                if let selectedCategory = menuManager.getCategoryById(selectedCategoryId) {
                    Text(selectedCategory.name)
                        .foregroundColor(.white)
                } else {
                    Text("Select Category")
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
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
    
    private var imageSelectionField: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dish Image")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Current image or placeholder
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                } else if let currentImageURL = currentImageURL, !currentImageURL.isEmpty {
                    AsyncImage(url: URL(string: currentImageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(12)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 200)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            )
                    }
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("No Image")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        )
                }
                
                // Image picker button
                Button(action: {
                    showImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 16, weight: .medium))
                        Text(selectedImage != nil ? "Change Image" : "Add Image")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.orange)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
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
                    
                    Text(isLoading ? (isUploadingImage ? "Uploading Image..." : "Saving...") : "Save Changes")
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
        
        // If there's a new image to upload, do that first
        if selectedImage != nil {
            uploadImage { imageURL in
                self.updateDishWithImageURL(imageURL)
            }
        } else {
            updateDishWithImageURL(currentImageURL)
        }
    }
    
    private func updateDishWithImageURL(_ imageURL: String?) {
        guard let priceValue = Double(price),
              let category = menuManager.getCategoryById(selectedCategoryId) else {
            isLoading = false
            return
        }
        
        let updatedDish = MenuDish(
            id: dish.id,
            name: dishName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: dishDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            price: priceValue,
            categoryId: selectedCategoryId,
            categoryName: category.name,
            imageURL: imageURL,
            isAvailable: isAvailable,
            allergens: Array(selectedAllergens),
            preparationTime: preparationTime,
            createdAt: dish.createdAt,
            updatedAt: Date()
        )
        
        menuManager.updateDish(updatedDish) { success in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.dismiss()
                }
            }
        }
    }
}

#Preview {
    EditDishView(
        menuManager: MenuManager(),
        dish: MenuDish(
            name: "Test Dish",
            description: "Test Description",
            price: 15.99,
            categoryId: "test-category",
            categoryName: "Test Category"
        )
    )
} 