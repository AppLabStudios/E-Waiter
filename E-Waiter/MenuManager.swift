import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Menu Models
struct MenuCategory: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let order: Int
    let isActive: Bool
    let createdAt: Date
    
    init(id: String = UUID().uuidString, name: String, description: String = "", order: Int = 0, isActive: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.order = order
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

struct MenuDish: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let categoryId: String
    let categoryName: String
    let imageURL: String?
    let isAvailable: Bool
    let allergens: [String]
    let preparationTime: Int // in minutes
    let createdAt: Date
    let updatedAt: Date
    
    init(id: String = UUID().uuidString, name: String, description: String, price: Double, categoryId: String, categoryName: String, imageURL: String? = nil, isAvailable: Bool = true, allergens: [String] = [], preparationTime: Int = 15, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.imageURL = imageURL
        self.isAvailable = isAvailable
        self.allergens = allergens
        self.preparationTime = preparationTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Menu Manager
class MenuManager: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var categories: [MenuCategory] = []
    @Published var dishes: [MenuDish] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    // Store restaurant ID for this session
    private var currentRestaurantId: String?
    
    // MARK: - Category Management
    
    func addCategory(name: String, description: String = "", completion: @escaping (Bool) -> Void) {
        guard let restaurantId = getCurrentRestaurantId() else {
            errorMessage = "Restaurant ID not found"
            completion(false)
            return
        }
        
        isLoading = true
        let category = MenuCategory(name: name, description: description, order: categories.count)
        
        let categoryData: [String: Any] = [
            "id": category.id,
            "name": category.name,
            "description": category.description,
            "order": category.order,
            "isActive": category.isActive,
            "createdAt": Timestamp(date: category.createdAt)
        ]
        
        db.collection("Restaurants").document(restaurantId)
            .collection("MenuCategories").document(category.id)
            .setData(categoryData) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = "Failed to add category: \(error.localizedDescription)"
                        completion(false)
                    } else {
                        self?.categories.append(category)
                        completion(true)
                    }
                }
            }
    }
    
    func updateCategory(_ category: MenuCategory, completion: @escaping (Bool) -> Void) {
        guard let restaurantId = getCurrentRestaurantId() else {
            errorMessage = "Restaurant ID not found"
            completion(false)
            return
        }
        
        isLoading = true
        let categoryData: [String: Any] = [
            "name": category.name,
            "description": category.description,
            "order": category.order,
            "isActive": category.isActive,
            "updatedAt": Timestamp(date: Date())
        ]
        
        db.collection("Restaurants").document(restaurantId)
            .collection("MenuCategories").document(category.id)
            .updateData(categoryData) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = "Failed to update category: \(error.localizedDescription)"
                        completion(false)
                    } else {
                        if let index = self?.categories.firstIndex(where: { $0.id == category.id }) {
                            self?.categories[index] = category
                        }
                        completion(true)
                    }
                }
            }
    }
    
    func deleteCategory(_ category: MenuCategory, completion: @escaping (Bool) -> Void) {
        guard let restaurantId = getCurrentRestaurantId() else {
            errorMessage = "Restaurant ID not found"
            completion(false)
            return
        }
        
        isLoading = true
        
        // First, check if there are dishes in this category
        db.collection("Restaurants").document(restaurantId)
            .collection("MenuDishes")
            .whereField("categoryId", isEqualTo: category.id)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        self?.errorMessage = "Failed to check dishes: \(error.localizedDescription)"
                        completion(false)
                    }
                    return
                }
                
                if let snapshot = snapshot, !snapshot.documents.isEmpty {
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        self?.errorMessage = "Cannot delete category with existing dishes. Please move or delete the dishes first."
                        completion(false)
                    }
                    return
                }
                
                // No dishes found, proceed with deletion
                self?.db.collection("Restaurants").document(restaurantId)
                    .collection("MenuCategories").document(category.id)
                    .delete { [weak self] error in
                        DispatchQueue.main.async {
                            self?.isLoading = false
                            if let error = error {
                                self?.errorMessage = "Failed to delete category: \(error.localizedDescription)"
                                completion(false)
                            } else {
                                self?.categories.removeAll { $0.id == category.id }
                                completion(true)
                            }
                        }
                    }
            }
    }
    
    // MARK: - Dish Management
    
    func addDish(_ dish: MenuDish, completion: @escaping (Bool) -> Void) {
        guard let restaurantId = getCurrentRestaurantId() else {
            errorMessage = "Restaurant ID not found"
            completion(false)
            return
        }
        
        isLoading = true
        let dishData: [String: Any] = [
            "id": dish.id,
            "name": dish.name,
            "description": dish.description,
            "price": dish.price,
            "categoryId": dish.categoryId,
            "categoryName": dish.categoryName,
            "imageURL": dish.imageURL ?? "",
            "isAvailable": dish.isAvailable,
            "allergens": dish.allergens,
            "preparationTime": dish.preparationTime,
            "createdAt": Timestamp(date: dish.createdAt),
            "updatedAt": Timestamp(date: dish.updatedAt)
        ]
        
        db.collection("Restaurants").document(restaurantId)
            .collection("MenuDishes").document(dish.id)
            .setData(dishData) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = "Failed to add dish: \(error.localizedDescription)"
                        completion(false)
                    } else {
                        self?.dishes.append(dish)
                        completion(true)
                    }
                }
            }
    }
    
    func updateDish(_ dish: MenuDish, completion: @escaping (Bool) -> Void) {
        guard let restaurantId = getCurrentRestaurantId() else {
            errorMessage = "Restaurant ID not found"
            completion(false)
            return
        }
        
        isLoading = true
        let dishData: [String: Any] = [
            "name": dish.name,
            "description": dish.description,
            "price": dish.price,
            "categoryId": dish.categoryId,
            "categoryName": dish.categoryName,
            "imageURL": dish.imageURL ?? "",
            "isAvailable": dish.isAvailable,
            "allergens": dish.allergens,
            "preparationTime": dish.preparationTime,
            "updatedAt": Timestamp(date: Date())
        ]
        
        db.collection("Restaurants").document(restaurantId)
            .collection("MenuDishes").document(dish.id)
            .updateData(dishData) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = "Failed to update dish: \(error.localizedDescription)"
                        completion(false)
                    } else {
                        if let index = self?.dishes.firstIndex(where: { $0.id == dish.id }) {
                            self?.dishes[index] = dish
                        }
                        completion(true)
                    }
                }
            }
    }
    
    func deleteDish(_ dish: MenuDish, completion: @escaping (Bool) -> Void) {
        guard let restaurantId = getCurrentRestaurantId() else {
            errorMessage = "Restaurant ID not found"
            completion(false)
            return
        }
        
        isLoading = true
        
        db.collection("Restaurants").document(restaurantId)
            .collection("MenuDishes").document(dish.id)
            .delete { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = "Failed to delete dish: \(error.localizedDescription)"
                        completion(false)
                    } else {
                        self?.dishes.removeAll { $0.id == dish.id }
                        completion(true)
                    }
                }
            }
    }
    
    // MARK: - Data Loading
    
    func loadMenuData(completion: @escaping (Bool) -> Void) {
        guard let restaurantId = getCurrentRestaurantId() else {
            errorMessage = "Restaurant ID not found"
            completion(false)
            return
        }
        
        isLoading = true
        
        let group = DispatchGroup()
        var loadError = false
        
        // Load categories
        group.enter()
        db.collection("Restaurants").document(restaurantId)
            .collection("MenuCategories")
            .order(by: "order")
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = "Failed to load categories: \(error.localizedDescription)"
                        loadError = true
                    } else if let snapshot = snapshot {
                        self?.categories = snapshot.documents.compactMap { document in
                            let data = document.data()
                            return MenuCategory(
                                id: document.documentID,
                                name: data["name"] as? String ?? "",
                                description: data["description"] as? String ?? "",
                                order: data["order"] as? Int ?? 0,
                                isActive: data["isActive"] as? Bool ?? true,
                                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                            )
                        }
                    }
                    group.leave()
                }
            }
        
        // Load dishes
        group.enter()
        db.collection("Restaurants").document(restaurantId)
            .collection("MenuDishes")
            .order(by: "categoryName")
            .order(by: "name")
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = "Failed to load dishes: \(error.localizedDescription)"
                        loadError = true
                    } else if let snapshot = snapshot {
                        self?.dishes = snapshot.documents.compactMap { document in
                            let data = document.data()
                            return MenuDish(
                                id: document.documentID,
                                name: data["name"] as? String ?? "",
                                description: data["description"] as? String ?? "",
                                price: data["price"] as? Double ?? 0.0,
                                categoryId: data["categoryId"] as? String ?? "",
                                categoryName: data["categoryName"] as? String ?? "",
                                imageURL: data["imageURL"] as? String,
                                isAvailable: data["isAvailable"] as? Bool ?? true,
                                allergens: data["allergens"] as? [String] ?? [],
                                preparationTime: data["preparationTime"] as? Int ?? 15,
                                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                                updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
                            )
                        }
                    }
                    group.leave()
                }
            }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            completion(!loadError)
        }
    }
    
    // MARK: - Helper Methods
    
    func getDishesForCategory(_ categoryId: String) -> [MenuDish] {
        return dishes.filter { $0.categoryId == categoryId }
    }
    
    func getCategoryById(_ categoryId: String) -> MenuCategory? {
        return categories.first { $0.id == categoryId }
    }
    
    private func getCurrentRestaurantId() -> String? {
        // First check if we have it stored in this session
        if let sessionRestaurantId = currentRestaurantId {
            print("🔍 MenuManager: Using session restaurant ID: \(sessionRestaurantId)")
            return sessionRestaurantId
        }
        
        // Get restaurant ID from the current AuthManager instance
        let restaurantId = AppStateManager.shared.authManager.deviceInfo?.restaurantId
        
        // Debug logging
        print("🔍 MenuManager: Attempting to get restaurant ID")
        print("🔍 MenuManager: deviceInfo = \(AppStateManager.shared.authManager.deviceInfo?.restaurantId ?? "nil")")
        print("🔍 MenuManager: isAuthenticated = \(AppStateManager.shared.authManager.isAuthenticated)")
        print("🔍 MenuManager: userRole = \(AppStateManager.shared.authManager.userRole)")
        
        // If we can't get it from deviceInfo, try to get it from UserDefaults
        if restaurantId == nil {
            print("⚠️ MenuManager: Restaurant ID not found in deviceInfo, checking UserDefaults")
            let storedRestaurantId = UserDefaults.standard.string(forKey: "currentRestaurantId")
            print("🔍 MenuManager: Stored restaurant ID = \(storedRestaurantId ?? "nil")")
            
            // Store it in session for future use
            if let storedRestaurantId = storedRestaurantId {
                currentRestaurantId = storedRestaurantId
            }
            
            return storedRestaurantId
        }
        
        // Store it in session for future use
        if let restaurantId = restaurantId {
            currentRestaurantId = restaurantId
        }
        
        return restaurantId
    }
    
    // Method to manually set restaurant ID (for testing or fallback)
    func setRestaurantId(_ restaurantId: String) {
        currentRestaurantId = restaurantId
        print("🔧 MenuManager: Manually set restaurant ID: \(restaurantId)")
    }
} 