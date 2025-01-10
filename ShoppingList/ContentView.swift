//
//  ContentView.swift
//  ShoppingList
//
//  Created by Onur Dabakoğlu on 10.01.2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddList = false
    @State private var showingEditList: ShoppingList?
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ShoppingList.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \ShoppingList.timestamp, ascending: false)
        ],
        animation: .default)
    private var shoppingLists: FetchedResults<ShoppingList>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(shoppingLists, id: \.self) { list in
                    HStack {
                        Button(action: {
                            toggleListCompletion(list)
                        }) {
                            Image(systemName: list.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(list.isCompleted ? .green : .gray)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        NavigationLink(destination: ShoppingListDetailView(shoppingList: list)) {
                            VStack(alignment: .leading) {
                                Text(list.name ?? "")
                                    .font(.headline)
                                    .strikethrough(list.isCompleted)
                                
                                HStack {
                                    if let dueDate = list.dueDate {
                                        Text("Due: \(dueDate, formatter: itemFormatter)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    if let items = list.items?.allObjects as? [ShoppingItem] {
                                        Text("\(items.count) items")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingEditList = list
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                .onDelete(perform: deleteLists)
            }
            .navigationTitle("Shopping Lists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddList = true
                    }) {
                        Label("Add List", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddList) {
                AddShoppingListView(isPresented: $showingAddList)
            }
            .sheet(item: $showingEditList) { list in
                EditShoppingListView(list: list, isPresented: Binding(
                    get: { showingEditList != nil },
                    set: { if !$0 { showingEditList = nil } }
                ))
            }
        }
    }
    
    private func toggleListCompletion(_ list: ShoppingList) {
        withAnimation {
            list.isCompleted.toggle()
            if list.isCompleted {
                list.completedDate = Date()
            } else {
                list.completedDate = nil
            }
            saveContext()
        }
    }
    
    private func deleteLists(offsets: IndexSet) {
        withAnimation {
            offsets.map { shoppingLists[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct ShoppingListDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var shoppingList: ShoppingList
    @FetchRequest private var items: FetchedResults<ShoppingItem>
    @State private var showingAddItem = false
    @State private var showingEditItem: ShoppingItem?
    @State private var selectedCategory = "All"
    
    let categories = ["All", "Groceries", "Electronics", "Clothing", "Home", "Other"]
    let units = ["piece", "kg", "liter", "gram", "ml"]
    
    init(shoppingList: ShoppingList) {
        self.shoppingList = shoppingList
        _items = FetchRequest(
            entity: ShoppingItem.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \ShoppingItem.isCompleted, ascending: true),
                NSSortDescriptor(keyPath: \ShoppingItem.timestamp, ascending: false)
            ],
            predicate: NSPredicate(format: "list == %@", shoppingList),
            animation: .default
        )
    }
    
    var filteredItems: [ShoppingItem] {
        selectedCategory == "All" 
            ? Array(items)
            : items.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        VStack {
            Picker("Category", selection: $selectedCategory) {
                ForEach(categories, id: \.self) { category in
                    Text(category)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            
            List {
                ForEach(filteredItems, id: \.self) { item in
                    HStack {
                        Button(action: {
                            toggleItemCompletion(item)
                        }) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(item.isCompleted ? .green : .gray)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        VStack(alignment: .leading) {
                            Text(item.name ?? "")
                                .strikethrough(item.isCompleted)
                            HStack {
                                Text(item.category ?? "")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Menu {
                                    Picker("Quantity", selection: Binding(
                                        get: { item.quantity },
                                        set: { newValue in
                                            withAnimation {
                                                item.quantity = newValue
                                                saveContext()
                                            }
                                        }
                                    )) {
                                        ForEach(Array(stride(from: 0.5, through: 20.0, by: 0.5)), id: \.self) { value in
                                            Text("\(value, specifier: "%.1f")")
                                        }
                                    }
                                } label: {
                                    Text("\(item.quantity, specifier: "%.1f")")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                
                                Menu {
                                    Picker("Unit", selection: Binding(
                                        get: { item.unit ?? "piece" },
                                        set: { newValue in
                                            withAnimation {
                                                item.unit = newValue
                                                saveContext()
                                            }
                                        }
                                    )) {
                                        ForEach(units, id: \.self) { unit in
                                            Text(unit)
                                        }
                                    }
                                } label: {
                                    Text(item.unit ?? "piece")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingEditItem = item
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle(shoppingList.name ?? "Shopping List")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddItem = true
                }) {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemView(shoppingList: shoppingList, isPresented: $showingAddItem, categories: Array(categories.dropFirst()))
        }
        .sheet(item: $showingEditItem) { item in
            EditItemView(item: item, isPresented: Binding(
                get: { showingEditItem != nil },
                set: { if !$0 { showingEditItem = nil } }
            ), categories: Array(categories.dropFirst()))
        }
    }
    
    private func toggleItemCompletion(_ item: ShoppingItem) {
        withAnimation {
            item.isCompleted.toggle()
            if item.isCompleted {
                item.completedDate = Date()
            } else {
                item.completedDate = nil
            }
            saveContext()
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredItems[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct EditShoppingListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var list: ShoppingList
    @Binding var isPresented: Bool
    @State private var listName: String
    @State private var dueDate: Date
    
    init(list: ShoppingList, isPresented: Binding<Bool>) {
        self.list = list
        self._isPresented = isPresented
        self._listName = State(initialValue: list.name ?? "")
        self._dueDate = State(initialValue: list.dueDate ?? Date())
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("List Name", text: $listName)
                DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
            }
            .navigationTitle("Edit List")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Save") {
                    updateList()
                }
                .disabled(listName.isEmpty)
            )
        }
    }
    
    private func updateList() {
        withAnimation {
            list.name = listName
            list.dueDate = dueDate
            
            do {
                try viewContext.save()
                isPresented = false
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct EditItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var item: ShoppingItem
    @Binding var isPresented: Bool
    @State private var itemName: String
    @State private var selectedCategory: String
    @State private var quantity: Double
    @State private var selectedUnit: String
    let categories: [String]
    let units = ["piece", "kg", "liter", "gram", "ml"]
    
    init(item: ShoppingItem, isPresented: Binding<Bool>, categories: [String]) {
        self.item = item
        self._isPresented = isPresented
        self.categories = categories
        self._itemName = State(initialValue: item.name ?? "")
        self._selectedCategory = State(initialValue: item.category ?? categories[0])
        self._quantity = State(initialValue: item.quantity)
        self._selectedUnit = State(initialValue: item.unit ?? "piece")
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Item Name", text: $itemName)
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category)
                    }
                }
                Picker("Quantity", selection: $quantity) {
                    ForEach(Array(stride(from: 0.5, through: 20.0, by: 0.5)), id: \.self) { value in
                        Text("\(value, specifier: "%.1f")")
                    }
                }
                Picker("Unit", selection: $selectedUnit) {
                    ForEach(units, id: \.self) { unit in
                        Text(unit)
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Save") {
                    updateItem()
                }
                .disabled(itemName.isEmpty || selectedCategory.isEmpty)
            )
        }
    }
    
    private func updateItem() {
        withAnimation {
            item.name = itemName
            item.category = selectedCategory
            item.quantity = quantity
            item.unit = selectedUnit
            
            do {
                try viewContext.save()
                isPresented = false
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct AddShoppingListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    @State private var listName = ""
    @State private var dueDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                TextField("List Name", text: $listName)
                DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
            }
            .navigationTitle("New Shopping List")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Save") {
                    addList()
                }
                .disabled(listName.isEmpty)
            )
        }
    }
    
    private func addList() {
        withAnimation {
            let newList = ShoppingList(context: viewContext)
            newList.name = listName
            newList.timestamp = Date()
            newList.dueDate = dueDate
            newList.isCompleted = false
            
            do {
                try viewContext.save()
                isPresented = false
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct AddItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let shoppingList: ShoppingList
    @Binding var isPresented: Bool
    @State private var itemName = ""
    @State private var selectedCategory = ""
    @State private var quantity: Double = 1.0
    @State private var selectedUnit = "piece"
    let categories: [String]
    let units = ["piece", "kg", "liter", "gram", "ml"]
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Item Name", text: $itemName)
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category)
                    }
                }
                Picker("Quantity", selection: $quantity) {
                    ForEach(Array(stride(from: 0.5, through: 20.0, by: 0.5)), id: \.self) { value in
                        Text("\(value, specifier: "%.1f")")
                    }
                }
                Picker("Unit", selection: $selectedUnit) {
                    ForEach(units, id: \.self) { unit in
                        Text(unit)
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Save") {
                    addItem()
                }
                .disabled(itemName.isEmpty || selectedCategory.isEmpty)
            )
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = ShoppingItem(context: viewContext)
            newItem.name = itemName
            newItem.category = selectedCategory
            newItem.timestamp = Date()
            newItem.isCompleted = false
            newItem.quantity = quantity
            newItem.unit = selectedUnit
            newItem.list = shoppingList
            
            do {
                try viewContext.save()
                isPresented = false
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
