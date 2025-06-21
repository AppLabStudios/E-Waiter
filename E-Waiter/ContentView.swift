//
//  ContentView.swift
//  E-Waiter
//
//  Created by Youssef Azroun on 2025-06-18.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ContentView: View {
    @StateObject private var appState = AppStateManager.shared
    
    var body: some View {
        if appState.isLoggedIn {
            switch appState.userRole {
            case .owner:
                OwnerView()
                    .environmentObject(appState)
            case .staff:
                StaffView()
                    .environmentObject(appState)
            case .table:
                TableView()
                    .environmentObject(appState)
            case .unactivated:
                // This shouldn't happen if authentication is successful
                LogIn(isLoggedIn: $appState.isLoggedIn, userRole: $appState.userRole)
            }
        } else {
            LogIn(isLoggedIn: $appState.isLoggedIn, userRole: $appState.userRole)
        }
    }
}

#Preview {
    ContentView()
}
