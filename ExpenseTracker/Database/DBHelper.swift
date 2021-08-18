//
//  DBHelper.swift
//  ExpenseTracker
//
//  Created by Gaurav Patel on 18/08/21.
//

import Foundation
import SQLite3

class DBHelper
{
    private init()
    {
        openDatabase()
    }
    static let shared = DBHelper()
    
    private let dbPath: String = "expense.sqlite"
    var database: SQLiteDatabase?
    
    func openDatabase()
    {
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(dbPath)
        print(fileURL.path)
        do {
            database = try SQLiteDatabase.open(path: fileURL.path )
            print("Successfully opened connection to database.")
            createTable()
        } catch  {
            print("Unable to open database.")
        }
        
    }
    func createTable()  {
        do {
            try database!.createTable(table: Category.self)
        } catch {
            print(database?.errorMessage as Any)
        }
        do {
            try database!.createTable(table: Expense.self)
        } catch {
            print(database?.errorMessage as Any)
        }
        do {
            try database!.createTable(table: Expense_Category.self)
        } catch {
            print(database?.errorMessage as Any)
        }
    }
    func createNewCategory(category:Category) {
        do {
            try database?.insertCategory(category: category)
        } catch {
            print(database?.errorMessage as Any)
        }
    }
    func createNewExpense(expense:Expense) {
        do {
            try database?.insertExpense(expense: expense)
        } catch {
            print(database?.errorMessage as Any)
        }
    }
    func fetchCategories() -> [Category] {
        do {
            return try database!.getAllCategories()
        } catch {
            print(database?.errorMessage as Any)
        }
        return []
    }
    
    func fetchAllExpense() -> [Expense] {
            do {
                return try database!.getAllExpense()
            } catch {
                print(database?.errorMessage as Any)
            }
            return []
        }
    
}
enum SQLiteError: Error {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
}
protocol SQLTable {
    static var createStatement: String { get }
}
class SQLiteDatabase {
    private let dbPointer: OpaquePointer?
    fileprivate var errorMessage: String {
        if let errorPointer = sqlite3_errmsg(dbPointer) {
            let errorMessage = String(cString: errorPointer)
            return errorMessage
        } else {
            return "No error message provided from sqlite."
        }
    }
    
    private init(dbPointer: OpaquePointer?) {
        self.dbPointer = dbPointer
    }
    deinit {
        sqlite3_close(dbPointer)
    }
    static func open(path: String) throws -> SQLiteDatabase {
        var db: OpaquePointer?
        // 1
        if sqlite3_open(path, &db) == SQLITE_OK {
            // 2
            return SQLiteDatabase(dbPointer: db)
        } else {
            // 3
            defer {
                if db != nil {
                    sqlite3_close(db)
                }
            }
            if let errorPointer = sqlite3_errmsg(db) {
                let message = String(cString: errorPointer)
                throw SQLiteError.OpenDatabase(message: message)
            } else {
                throw SQLiteError
                .OpenDatabase(message: "No error message provided from sqlite.")
            }
        }
    }
    
}
extension SQLiteDatabase {
    func prepareStatement(sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil)
                == SQLITE_OK else {
            throw SQLiteError.Prepare(message: errorMessage)
        }
        return statement
    }
}

extension SQLiteDatabase {
    func createTable(table: SQLTable.Type) throws {
        // 1
        let createTableStatement = try prepareStatement(sql: table.createStatement)
        // 2
        defer {
            sqlite3_finalize(createTableStatement)
        }
        // 3
        guard sqlite3_step(createTableStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        print("\(table) table created.")
    }
}
extension SQLiteDatabase {
    func insertCategory(category: Category) throws {
        let insertSql = "INSERT INTO category (name) VALUES (?);"
        let insertStatement = try prepareStatement(sql: insertSql)
        defer {
            sqlite3_finalize(insertStatement)
        }
        let name: NSString = category.name as NSString
        guard
            sqlite3_bind_text(insertStatement, 1, name.utf8String, -1, nil)
                == SQLITE_OK
        else {
            throw SQLiteError.Bind(message: errorMessage)
        }
        guard sqlite3_step(insertStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        print("Successfully inserted row.")
        let lastRowId = sqlite3_last_insert_rowid(dbPointer);
        print(lastRowId) // its gives you last insert id
    }
    func getAllCategories() throws -> [Category]  {
        let querySql = "SELECT * FROM category;"
        let queryStatement = try prepareStatement(sql: querySql)
        var allCategories:[Category] = []
        
        defer {
            sqlite3_finalize(queryStatement)
        }
        
        while sqlite3_step(queryStatement) == SQLITE_ROW {
            let id = sqlite3_column_int(queryStatement, 0)
            let name = String(cString: sqlite3_column_text(queryStatement, 1))
            allCategories.append(Category(id: id, name: name))
            print("Query Result:")
            print("\(id) | \(name) ")
        }
        
        
        return allCategories
    }
    func getAllExpense() throws -> [Expense]  {
            let querySql = "SELECT expense.id, expense.name,expense.amount,expense.dateTime,GROUP_CONCAT(category.id, '||'), GROUP_CONCAT(category.name, '||') FROM expense INNER JOIN expense_category ON expense.id = expense_category.expense_id INNER JOIN category ON category.id = expense_category.category_id GROUP BY expense.id;"
            let queryStatement = try prepareStatement(sql: querySql)
            var allExpenses:[Expense] = []
            
            defer {
                sqlite3_finalize(queryStatement)
            }
            
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = sqlite3_column_int(queryStatement, 0)
                let name = String(cString: sqlite3_column_text(queryStatement, 1))
                let amount = sqlite3_column_double(queryStatement, 2)
                let dateTimeStamp = sqlite3_column_double(queryStatement, 3)

                let category_ids = String(cString: sqlite3_column_text(queryStatement, 4))
                let category_names = String(cString: sqlite3_column_text(queryStatement, 5))
                let arrCategoryID = category_ids.components(separatedBy: "||")
                let arrCategoryName = category_names.components(separatedBy: "||")
                var expenseCategories:[Category] = []

                for (id, name) in zip(arrCategoryID, arrCategoryName) {
                    expenseCategories.append(Category(id: Int32(id)!, name: name))
                }
                let expense  = Expense(id: id, name: name, amount: amount, categories: expenseCategories, dateTime: dateTimeStamp)

                allExpenses.append(expense)
            }
            
            
            return allExpenses
        }
    
}
extension SQLiteDatabase {
    func insertExpense(expense: Expense) throws {
        let insertSql = "INSERT INTO expense (name,amount,dateTime) VALUES (?,?,?);"
        let insertStatement = try prepareStatement(sql: insertSql)
        defer {
            sqlite3_finalize(insertStatement)
        }
        let name: NSString = expense.name as NSString
        guard
            sqlite3_bind_text(insertStatement, 1, name.utf8String, -1, nil)
                == SQLITE_OK &&
                sqlite3_bind_double(insertStatement, 2, expense.amount)
                == SQLITE_OK &&
                sqlite3_bind_double(insertStatement, 3, expense.dateTime)
                               == SQLITE_OK
        else {
            throw SQLiteError.Bind(message: errorMessage)
        }
        guard sqlite3_step(insertStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        print("Successfully inserted row.")
        let lastRowId = sqlite3_last_insert_rowid(dbPointer);
        print(lastRowId) // its gives you last insert id
        try insertExpense_categories(expense_id: Int32(lastRowId), categories: expense.categories)
    }
    func insertExpense_categories(expense_id:Int32,categories:[Category]) throws {
        let insertSql = "INSERT INTO expense_category (expense_id,category_id) VALUES (?,?);"
        let insertStatement = try prepareStatement(sql: insertSql)
        defer {
            sqlite3_finalize(insertStatement)
        }
        for category in categories {
            guard sqlite3_bind_int(insertStatement, 1, expense_id) == SQLITE_OK &&
                    sqlite3_bind_int(insertStatement, 2, category.id)
                    == SQLITE_OK
            else {
                throw SQLiteError.Bind(message: errorMessage)
            }
            guard sqlite3_step(insertStatement) == SQLITE_DONE else {
                throw SQLiteError.Step(message: errorMessage)
            }
            sqlite3_reset(insertStatement);
            print("Successfully inserted expense_category row.")
            
        }
        
        let lastRowId = sqlite3_last_insert_rowid(dbPointer);
        print(lastRowId) // its gives you last insert id
    }
}
