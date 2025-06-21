import Foundation
import FirebaseFirestore
import UIKit

class DeviceManager: ObservableObject {
    private let db = Firestore.firestore()
    
    // Get unique device identifier
    var deviceId: String {
        if let identifier = UIDevice.current.identifierForVendor?.uuidString {
            return identifier
        }
        // Fallback to a generated UUID if device identifier is not available
        return UUID().uuidString
    }
    
    // Check if device exists in restaurant's devices subcollection
    func checkDeviceExists(restaurantId: String, completion: @escaping (DeviceInfo?) -> Void) {
        let deviceRef = db.collection("Restaurants").document(restaurantId).collection("Devices").document(deviceId)
        
        deviceRef.getDocument { document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error checking device: \(error)")
                    completion(nil)
                    return
                }
                
                if let document = document, document.exists {
                    // Device exists, parse the data
                    let data = document.data()
                    let deviceInfo = DeviceInfo(
                        deviceId: self.deviceId,
                        deviceRole: data?["deviceRole"] as? String ?? "",
                        activated: data?["activated"] as? Bool ?? false,
                        tableNumber: data?["tableNumber"] as? String ?? "",
                        lastLogin: data?["lastLogin"] as? Timestamp ?? Timestamp(),
                        restaurantId: restaurantId
                    )
                    completion(deviceInfo)
                } else {
                    // Device doesn't exist
                    completion(nil)
                }
            }
        }
    }
    
    // Check if device is assigned to any restaurant
    func checkDeviceAssignedToAnyRestaurant(completion: @escaping (DeviceInfo?) -> Void) {
        print("🔍 Checking if device \(deviceId) is assigned to any restaurant")
        
        // Query all restaurants to check if device exists in any of them
        db.collection("Restaurants").getDocuments { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error querying restaurants: \(error)")
                    completion(nil)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("❌ No restaurants found")
                    completion(nil)
                    return
                }
                
                print("🔍 Found \(documents.count) restaurants to check")
                
                // Check each restaurant's devices subcollection
                let group = DispatchGroup()
                var foundDevice: DeviceInfo?
                
                for restaurantDoc in documents {
                    group.enter()
                    
                    let deviceRef = restaurantDoc.reference.collection("Devices").document(self.deviceId)
                    deviceRef.getDocument { document, error in
                        defer { group.leave() }
                        
                        if let document = document, document.exists {
                            let data = document.data() ?? [:]
                            foundDevice = DeviceInfo(
                                deviceId: self.deviceId,
                                deviceRole: data["deviceRole"] as? String ?? "",
                                activated: data["activated"] as? Bool ?? false,
                                tableNumber: data["tableNumber"] as? String ?? "",
                                lastLogin: data["lastLogin"] as? Timestamp ?? Timestamp(),
                                restaurantId: restaurantDoc.documentID
                            )
                            print("✅ Device found in restaurant: \(restaurantDoc.documentID)")
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    if let device = foundDevice {
                        print("✅ Device is already assigned to restaurant: \(device.restaurantId)")
                        completion(device)
                    } else {
                        print("✅ Device is not assigned to any restaurant")
                        completion(nil)
                    }
                }
            }
        }
    }
    
    // Save new device to restaurant's devices subcollection
    func saveNewDevice(restaurantId: String, completion: @escaping (Bool) -> Void) {
        let deviceRef = db.collection("Restaurants").document(restaurantId).collection("Devices").document(deviceId)
        
        let deviceData: [String: Any] = [
            "deviceId": deviceId,
            "activated": false,
            "deviceRole": "",
            "tableNumber": "",
            "lastLogin": Timestamp(),
            "createdAt": Timestamp()
        ]
        
        deviceRef.setData(deviceData) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error saving device: \(error)")
                    completion(false)
                } else {
                    print("✅ New device saved to restaurant: \(restaurantId)")
                    completion(true)
                }
            }
        }
    }
    
    // Update device last login time
    func updateLastLogin(restaurantId: String, completion: @escaping (Bool) -> Void) {
        let deviceRef = db.collection("Restaurants").document(restaurantId).collection("Devices").document(deviceId)
        
        let updateData: [String: Any] = [
            "lastLogin": Timestamp()
        ]
        
        deviceRef.updateData(updateData) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error updating last login: \(error)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
}

// Device information model
struct DeviceInfo {
    let deviceId: String
    let deviceRole: String // "owner", "staff", "table"
    let activated: Bool
    let tableNumber: String
    let lastLogin: Timestamp
    let restaurantId: String // Which restaurant this device belongs to
}

// User role enum
enum UserRole {
    case owner
    case staff
    case table
    case unactivated
    
    init(from deviceRole: String) {
        switch deviceRole.lowercased() {
        case "owner":
            self = .owner
        case "staff":
            self = .staff
        case "table":
            self = .table
        default:
            self = .unactivated
        }
    }
} 