# E-Waiter Database Structure

## Overview
E-Waiter is a restaurant management system that supports multiple device types (Owner, Staff, and Table devices) for the same restaurant account. Each device login is tracked separately with unique device IDs and session management.

## Database Collections

### 1. Restaurants Collection
**Path:** `Restaurants/{restaurantId}`

**Fields:**
- `city` (string) - Restaurant's city location
- `createdAt` (string) - Restaurant creation timestamp
- `email` (string) - Restaurant owner's email
- `restaurantName` (string) - Name of the restaurant
- `status` (boolean) - Restaurant active status
- `userId` (string) - Firebase Auth user ID of the restaurant owner

**Example:**
```json
{
  "city": "New York",
  "createdAt": "2024-01-15T10:30:00Z",
  "email": "owner@restaurant.com",
  "restaurantName": "Sample Restaurant",
  "status": true,
  "userId": "firebase_auth_user_id_here"
}
```

### 2. Devices Subcollection
**Path:** `Restaurants/{restaurantId}/Devices/{deviceId}`

**Purpose:** Manages device authentication and role assignment for a specific restaurant.

**Fields:**
- `deviceId` (string) - Unique device identifier (UIDevice.identifierForVendor)
- `deviceRole` (string) - "owner", "staff", or "table"
- `activated` (boolean) - Whether the device is activated by the owner
- `tableNumber` (string) - Table number (empty for owner/staff, number for tables)
- `lastLogin` (timestamp) - Last login timestamp
- `createdAt` (timestamp) - When the device was first registered

**Example:**
```json
{
  "deviceId": "device_uuid_here",
  "deviceRole": "table",
  "activated": true,
  "tableNumber": "3",
  "lastLogin": "2024-01-15T14:30:00Z",
  "createdAt": "2024-01-15T10:00:00Z"
}
```

### 3. MenuCategories Subcollection
**Path:** `Restaurants/{restaurantId}/MenuCategories/{categoryId}`

**Purpose:** Stores menu categories for organizing dishes.

**Fields:**
- `id` (string) - Unique category identifier
- `name` (string) - Category name (e.g., "Main Course", "Desserts", "Drinks")
- `description` (string) - Optional category description
- `order` (number) - Display order for sorting
- `isActive` (boolean) - Whether the category is visible to customers
- `createdAt` (timestamp) - When the category was created

**Example:**
```json
{
  "id": "category_uuid_here",
  "name": "Main Course",
  "description": "Our signature main dishes",
  "order": 1,
  "isActive": true,
  "createdAt": "2024-01-15T10:00:00Z"
}
```

### 4. MenuDishes Subcollection
**Path:** `Restaurants/{restaurantId}/MenuDishes/{dishId}`

**Purpose:** Stores individual menu items/dishes.

**Fields:**
- `id` (string) - Unique dish identifier
- `name` (string) - Dish name
- `description` (string) - Dish description and ingredients
- `price` (number) - Dish price in currency units
- `categoryId` (string) - Reference to the category this dish belongs to
- `categoryName` (string) - Category name for easy querying
- `imageURL` (string) - Optional image URL for the dish
- `isAvailable` (boolean) - Whether the dish is available for ordering
- `allergens` (array) - List of allergens (e.g., ["Gluten", "Dairy"])
- `preparationTime` (number) - Preparation time in minutes
- `createdAt` (timestamp) - When the dish was created
- `updatedAt` (timestamp) - When the dish was last updated

**Example:**
```json
{
  "id": "dish_uuid_here",
  "name": "Pasta Carbonara",
  "description": "Classic Italian pasta with eggs, cheese, and pancetta",
  "price": 18.99,
  "categoryId": "category_uuid_here",
  "categoryName": "Main Course",
  "imageURL": "https://example.com/carbonara.jpg",
  "isAvailable": true,
  "allergens": ["Gluten", "Dairy", "Eggs"],
  "preparationTime": 20,
  "createdAt": "2024-01-15T10:00:00Z",
  "updatedAt": "2024-01-15T10:00:00Z"
}
```

## Database Structure Benefits

### Hierarchical Organization
```
Restaurants/
├── restaurant_1/
│   ├── city: "New York"
│   ├── restaurantName: "Sample Restaurant"
│   ├── userId: "owner_user_id"
│   ├── Devices/
│   │   ├── device_1 (Owner device)
│   │   ├── device_2 (Staff device)
│   │   ├── device_3 (Table 1)
│   │   └── device_4 (Table 2)
│   ├── MenuCategories/
│   │   ├── category_1 (Main Course)
│   │   ├── category_2 (Desserts)
│   │   └── category_3 (Drinks)
│   └── MenuDishes/
│       ├── dish_1 (Pasta Carbonara)
│       ├── dish_2 (Tiramisu)
│       └── dish_3 (Espresso)
└── restaurant_2/
    ├── city: "Los Angeles"
    ├── restaurantName: "Another Restaurant"
    ├── userId: "another_owner_id"
    ├── Devices/
    │   ├── device_5 (Owner device)
    │   └── device_6 (Table 1)
    ├── MenuCategories/
    │   └── category_4 (Main Course)
    └── MenuDishes/
        └── dish_4 (Burger)
```

### Advantages
1. **Better Organization** - All sessions for a restaurant are grouped together
2. **Easier Queries** - Can easily get all sessions for a specific restaurant
3. **Scalability** - Each restaurant's data is isolated
4. **Security** - Can implement restaurant-specific security rules
5. **Performance** - Queries are more efficient when scoped to a restaurant

## User Types and Device Management

### Owner Devices
- **User Type:** "Owner"
- **Table Number:** 0
- **Purpose:** Restaurant management, menu management, analytics
- **Multiple Devices:** Yes, multiple owner devices can be logged in simultaneously

### Staff Devices
- **User Type:** "Staff"
- **Table Number:** 0
- **Purpose:** Order management, table status, customer service
- **Multiple Devices:** Yes, multiple staff devices can be logged in simultaneously

### Table Devices
- **User Type:** "Table"
- **Table Number:** Auto-incremented (1, 2, 3, ...)
- **Purpose:** Customer ordering, menu viewing, bill requests
- **Multiple Devices:** Yes, each table device gets a unique table number

## Session Management

### Login Process
1. User authenticates with Firebase Auth
2. System validates restaurant ID and user authorization
3. Device ID is generated using `UIDevice.current.identifierForVendor`
4. For table devices, system determines next available table number
5. Session is saved to `Restaurants/{restaurantId}/Sessions` subcollection
6. User is navigated to appropriate view (OwnerView, StaffView, or TableView)

### Table Numbering Logic
- System queries existing active table sessions for the specific restaurant
- Finds the highest table number currently in use
- Assigns the next available number (max + 1)
- If no tables exist, starts with table number 1

### Logout Process
1. User clicks logout button
2. System finds the active session for the current device in the restaurant's Sessions subcollection
3. Updates session with `isActive: false` and `logoutTime`
4. Signs out from Firebase Auth
5. User is returned to login screen

### Session Recovery
1. App checks Firebase Auth status
2. Queries all restaurants to find active sessions for the current user
3. Restores session data and navigates to appropriate view
4. If no active session found, shows login screen

## Security Features

### Authentication
- Firebase Authentication for user login
- Restaurant ID validation against user ownership
- Session-based access control

### Authorization
- Only restaurant owners can access their restaurant data
- Device-specific session tracking
- Automatic session cleanup on logout

## Data Flow

### Login Flow
```
User Input → Firebase Auth → Restaurant Validation → Device ID Generation → 
Table Number Assignment (if table) → Session Creation in Restaurant Subcollection → Navigation to View
```

### Session Recovery
```
App Launch → Check Firebase Auth → Query All Restaurants for Active Sessions → 
Restore Session Data → Navigate to Appropriate View
```

### Logout Flow
```
Logout Request → Session Deactivation in Restaurant Subcollection → Firebase Sign Out → 
Return to Login Screen
```

## Future Enhancements

### Implemented Collections
- `Restaurants/{restaurantId}/Devices` - Device management and authentication
- `Restaurants/{restaurantId}/MenuCategories` - Menu category management
- `Restaurants/{restaurantId}/MenuDishes` - Menu dish management

### Planned Collections
- `Restaurants/{restaurantId}/Orders` - Customer orders
- `Restaurants/{restaurantId}/Payments` - Payment transactions
- `Restaurants/{restaurantId}/Analytics` - Restaurant performance data
- `Restaurants/{restaurantId}/Staff` - Staff member information
- `Restaurants/{restaurantId}/Tables` - Table configuration and status

### Features to Implement
- Real-time order synchronization
- Push notifications for new orders
- Payment processing integration
- Inventory management
- Customer feedback system
- Advanced analytics dashboard

## Best Practices

### Database Rules
- Implement Firestore security rules per restaurant
- Restrict access based on user authentication and restaurant ownership
- Validate data on both client and server side

### Performance
- Use indexes for frequently queried fields within restaurant scope
- Implement pagination for large datasets
- Cache frequently accessed data per restaurant

### Scalability
- Design supports multiple restaurants with isolated data
- Plan for high concurrent user loads per restaurant
- Consider regional data distribution for global restaurants 