//
//  Expense.swift
//  ExpenseTracker
//
//  Created by Gaurav Patel on 18/08/21.
//

import Foundation

struct Expense {
    let id: Int32
    let name: String
    let amount: Double
    let categories:[Category]
    let dateTime:Double
}
extension Expense: SQLTable {
    static var createStatement: String {
        return """
    CREATE TABLE IF NOT EXISTS expense(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name CHAR(255),
      amount REAL,
      dateTime REAL
    );
    """
    }
}
