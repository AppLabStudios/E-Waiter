import SwiftUI

struct MenuManagementView: View {
    @StateObject private var menuManager = MenuManager()
    @State private var selectedTab = 0
    @State private var showAddCategory = false
    @State private var showAddDish = false
    @State private var animateCards = false
    @State private var showWelcomeAnimation = false
    
    var body: some View {
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
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Main content
                    mainContentView(geometry: geometry)
                }
            }
        }
        .onAppear {
            // Initialize restaurant ID if needed
            if let storedRestaurantId = UserDefaults.standard.string(forKey: "currentRestaurantId") {
                menuManager.setRestaurantId(storedRestaurantId)
            }
            
            loadMenuData()
            withAnimation(.easeOut(duration: 0.8)) {
                showWelcomeAnimation = true
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animateCards = true
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView(menuManager: menuManager)
        }
        .sheet(isPresented: $showAddDish) {
            AddDishView(menuManager: menuManager)
        }
        .alert("Error", isPresented: .constant(!menuManager.errorMessage.isEmpty)) {
            Button("OK") {
                menuManager.errorMessage = ""
            }
        } message: {
            Text(menuManager.errorMessage)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Menu Management")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(showWelcomeAnimation ? 1 : 0)
                        .offset(y: showWelcomeAnimation ? 0 : -20)
                    
                    Text("Manage your restaurant menu")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(showWelcomeAnimation ? 1 : 0)
                        .offset(y: showWelcomeAnimation ? 0 : -10)
                }
                
                Spacer()
                
                // Stats cards
                HStack(spacing: 20) {
                    StatCard(title: "Categories", value: "\(menuManager.categories.count)", icon: "folder.fill", color: .blue)
                    StatCard(title: "Dishes", value: "\(menuManager.dishes.count)", icon: "fork.knife", color: .green)
                    StatCard(title: "Available", value: "\(menuManager.dishes.filter { $0.isAvailable }.count)", icon: "checkmark.circle", color: .orange)
                }
                .opacity(showWelcomeAnimation ? 1 : 0)
                .offset(x: showWelcomeAnimation ? 0 : 50)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            .padding(.bottom, 30)
            
            // Tab bar
            tabBarView
        }
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.1), Color.clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(height: 1)
                        .offset(y: 1)
                )
        )
    }
    
    // MARK: - Tab Bar
    private var tabBarView: some View {
        HStack(spacing: 0) {
            ForEach(0..<2) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: tabIcons[index])
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(selectedTab == index ? .white : .white.opacity(0.6))
                        
                        Text(tabTitles[index])
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedTab == index ? .white : .white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Rectangle()
                            .fill(selectedTab == index ? Color.white.opacity(0.1) : Color.clear)
                            .cornerRadius(12)
                    )
                }
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 20)
    }
    
    // MARK: - Main Content
    private func mainContentView(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: 30) {
                switch selectedTab {
                case 0:
                    categoriesTab
                case 1:
                    dishesTab
                default:
                    categoriesTab
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 30)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Categories Tab
    private var categoriesTab: some View {
        VStack(spacing: 30) {
            // Add category button
            Button(action: {
                showAddCategory = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.green)
                    
                    Text("Add New Category")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .offset(y: animateCards ? 0 : 30)
            .opacity(animateCards ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.1), value: animateCards)
            
            // Categories list
            if menuManager.categories.isEmpty {
                emptyCategoriesView
            } else {
                categoriesListView
            }
        }
    }
    
    // MARK: - Dishes Tab
    private var dishesTab: some View {
        VStack(spacing: 30) {
            // Add dish button
            Button(action: {
                showAddDish = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.orange)
                    
                    Text("Add New Dish")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .offset(y: animateCards ? 0 : 30)
            .opacity(animateCards ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.1), value: animateCards)
            
            // Dishes list
            if menuManager.dishes.isEmpty {
                emptyDishesView
            } else {
                dishesListView
            }
        }
    }
    
    // MARK: - Empty States
    private var emptyCategoriesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No Categories Yet")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Create your first menu category to organize your dishes")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .offset(y: animateCards ? 0 : 30)
        .opacity(animateCards ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: animateCards)
    }
    
    private var emptyDishesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No Dishes Yet")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Add your first dish to start building your menu")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .offset(y: animateCards ? 0 : 30)
        .opacity(animateCards ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: animateCards)
    }
    
    // MARK: - Lists
    private var categoriesListView: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(menuManager.categories.enumerated()), id: \.element.id) { index, category in
                CategoryCard(
                    category: category,
                    dishCount: menuManager.getDishesForCategory(category.id).count,
                    onEdit: {
                        // Handle edit
                    },
                    onDelete: {
                        deleteCategory(category)
                    }
                )
                .offset(y: animateCards ? 0 : 50)
                .opacity(animateCards ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: animateCards)
            }
        }
    }
    
    private var dishesListView: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(menuManager.dishes.enumerated()), id: \.element.id) { index, dish in
                DishCard(
                    dish: dish,
                    onEdit: {
                        // Handle edit
                    },
                    onDelete: {
                        deleteDish(dish)
                    }
                )
                .offset(y: animateCards ? 0 : 50)
                .opacity(animateCards ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: animateCards)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadMenuData() {
        menuManager.loadMenuData { success in
            if !success {
                print("Failed to load menu data")
            }
        }
    }
    
    private func deleteCategory(_ category: MenuCategory) {
        menuManager.deleteCategory(category) { success in
            if success {
                print("Category deleted successfully")
            }
        }
    }
    
    private func deleteDish(_ dish: MenuDish) {
        menuManager.deleteDish(dish) { success in
            if success {
                print("Dish deleted successfully")
            }
        }
    }
    
    // MARK: - Data Arrays
    private let tabIcons = ["folder.fill", "fork.knife"]
    private let tabTitles = ["Categories", "Dishes"]
}

// MARK: - Supporting Views
struct CategoryCard: View {
    let category: MenuCategory
    let dishCount: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Category icon
            VStack {
                Image(systemName: "folder.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("\(dishCount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(width: 50)
            
            // Category info
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                if !category.description.isEmpty {
                    Text(category.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                HStack {
                    Text("\(dishCount) dishes")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    if !category.isActive {
                        Text("Inactive")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.red.opacity(0.2))
                            )
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
                
                Button(action: {
                    showDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .alert("Delete Category", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(category.name)'? This action cannot be undone.")
        }
    }
}

struct DishCard: View {
    let dish: MenuDish
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Dish image
            if let imageURL = dish.imageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("\(dish.preparationTime)m")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            } else {
                VStack {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.orange)
                    
                    Text("\(dish.preparationTime)m")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(width: 60, height: 60)
            }
            
            // Dish info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(dish.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", dish.price))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                }
                
                if !dish.description.isEmpty {
                    Text(dish.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                HStack {
                    Text(dish.categoryName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(0.2))
                        )
                    
                    Spacer()
                    
                    if !dish.isAvailable {
                        Text("Unavailable")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.red.opacity(0.2))
                            )
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
                
                Button(action: {
                    showDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .alert("Delete Dish", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(dish.name)'? This action cannot be undone.")
        }
    }
}

#Preview {
    MenuManagementView()
} 