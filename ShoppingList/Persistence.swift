//
//  Persistence.swift
//  ShoppingList
//
//  Created by Onur Dabakoğlu on 10.01.2025.
//

import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        do {
            // Create sample shopping lists
            let groceryList = createShoppingList(name: "Grocery Shopping", dueDate: Date().addingTimeInterval(86400), isCompleted: false, in: viewContext)
            let electronicsList = createShoppingList(name: "Electronics", dueDate: Date().addingTimeInterval(172800), isCompleted: true, in: viewContext)
            
            // Add items to grocery list
            createShoppingItem(name: "Milk", category: "Groceries", quantity: 2, isCompleted: true, in: viewContext, list: groceryList)
            createShoppingItem(name: "Bread", category: "Groceries", quantity: 1, isCompleted: false, in: viewContext, list: groceryList)
            createShoppingItem(name: "Eggs", category: "Groceries", quantity: 12, isCompleted: false, in: viewContext, list: groceryList)
            
            // Add items to electronics list
            createShoppingItem(name: "USB Cable", category: "Electronics", quantity: 1, isCompleted: true, in: viewContext, list: electronicsList)
            createShoppingItem(name: "Power Bank", category: "Electronics", quantity: 1, isCompleted: true, in: viewContext, list: electronicsList)
            
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    static func createShoppingList(name: String, dueDate: Date, isCompleted: Bool, in context: NSManagedObjectContext) -> ShoppingList {
        let list = ShoppingList(context: context)
        list.name = name
        list.timestamp = Date()
        list.dueDate = dueDate
        list.isCompleted = isCompleted
        list.completedDate = isCompleted ? Date() : nil
        return list
    }
    
    static func createShoppingItem(name: String, category: String, quantity: Int32, isCompleted: Bool, in context: NSManagedObjectContext, list: ShoppingList) {
        let item = ShoppingItem(context: context)
        item.name = name
        item.category = category
        item.quantity = Double(quantity)
        item.timestamp = Date()
        item.isCompleted = isCompleted
        item.completedDate = isCompleted ? Date() : nil
        item.list = list
    }

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ShoppingList")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
