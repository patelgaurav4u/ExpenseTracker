//
//  Expense_Category.swift
//  ExpenseTracker
//
//  Created by Gaurav Patel on 18/08/21.
//

import Foundation
import Foundation

struct Expense_Category {
    let id: Int32
    let expense_id: Int32
    let category_id:Int32
}
extension Expense_Category: SQLTable {
    static var createStatement: String {
        return """
    CREATE TABLE IF NOT EXISTS expense_category(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      expense_id INTEGER,
      category_id INTEGER
    );
    """
    }
}
