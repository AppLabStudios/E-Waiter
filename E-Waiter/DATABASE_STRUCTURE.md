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

### 2. Sessions Subcollection
**Path:** `Restaurants/{restaurantId}/Sessions/{sessionId}`

**Purpose:** Tracks all active device logins for a specific restaurant.

**Fields:**
- `userId` (string) - Firebase Auth user ID
- `deviceId` (string) - Unique device identifier (UIDevice.identifierForVendor)
- `userType` (string) - "Owner", "Staff", or "Table"
- `tableNumber` (number) - Table number (0 for Owner/Staff, 1+ for Tables)
- `isActive` (boolean) - Session active status
- `loginTime` (timestamp) - When the session started
- `lastActivity` (timestamp) - Last activity timestamp
- `logoutTime` (timestamp) - When the session ended (optional)

**Example:**
```json
{
  "userId": "firebase_auth_user_id",
  "deviceId": "device_uuid_here",
  "userType": "Table",
  "tableNumber": 3,
  "isActive": true,
  "loginTime": "2024-01-15T14:30:00Z",
  "lastActivity": "2024-01-15T16:45:00Z"
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
│   └── Sessions/
│       ├── session_1 (Owner device)
│       ├── session_2 (Staff device)
│       ├── session_3 (Table 1)
│       └── session_4 (Table 2)
└── restaurant_2/
    ├── city: "Los Angeles"
    ├── restaurantName: "Another Restaurant"
    ├── userId: "another_owner_id"
    └── Sessions/
        ├── session_5 (Owner device)
        └── session_6 (Table 1)
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

### Planned Collections
- `Restaurants/{restaurantId}/Menu` - Restaurant menu items
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