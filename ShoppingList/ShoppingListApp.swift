//
//  ShoppingListApp.swift
//  ShoppingList
//
//  Created by Onur Dabakoğlu on 10.01.2025.
//

import SwiftUI

@main
struct ShoppingListApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
