//
//  Category.swift
//  ExpenseTracker
//
//  Created by Gaurav Patel on 18/08/21.
//

import Foundation

struct Category {
  let id: Int32
  let name: String
}
extension Category: SQLTable {
  static var createStatement: String {
    return """
    CREATE TABLE IF NOT EXISTS category(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name CHAR(255)
    );
    """
  }
}
