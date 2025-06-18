//
//  ContentView.swift
//  E-Waiter
//
//  Created by Youssef Azroun on 2025-06-18.
//

import SwiftUI
import FirebaseFirestore

struct Restaurant: Identifiable {
    let id: String
    let restaurantName: String
}

struct ContentView: View {
    @State private var restaurants: [Restaurant] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading restaurants...")
                        .padding()
                } else if let error = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text("Error")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else if restaurants.isEmpty {
                    VStack {
                        Image(systemName: "fork.knife")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No restaurants found")
                            .font(.headline)
                            .padding()
                    }
                } else {
                    List(restaurants) { restaurant in
                        HStack {
                            Image(systemName: "building.2")
                                .foregroundColor(.blue)
                            Text(restaurant.restaurantName)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("E-Waiter")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            fetchRestaurants()
        }
    }
    
    private func fetchRestaurants() {
        let db = Firestore.firestore()
        
        db.collection("Restaurants").getDocuments { snapshot, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Error fetching restaurants: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    errorMessage = "No documents found"
                    return
                }
                
                restaurants = documents.compactMap { document in
                    let data = document.data()
                    guard let restaurantName = data["restaurantName"] as? String else {
                        return nil
                    }
                    return Restaurant(id: document.documentID, restaurantName: restaurantName)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
