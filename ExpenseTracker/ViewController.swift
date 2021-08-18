//
//  ViewController.swift
//  ExpenseTracker
//
//  Created by Gaurav Patel on 17/08/21.
//

import UIKit

class ViewController: UIViewController {


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        DBHelper.shared.createNewCategory(category: Category(id: 0, name: "Testing"))
        DBHelper.shared.createNewCategory(category: Category(id: 0, name: "Testing12"))
        DBHelper.shared.createNewCategory(category: Category(id: 0, name: "Testing21212"))
        
        let categories = DBHelper.shared.fetchCategories()
        if categories.count > 0{
            let expense  = Expense(id: 0, name: "Test Expense", amount: 12.05, categories: [categories[0]], dateTime: Date().timeIntervalSince1970)
            DBHelper.shared.createNewExpense(expense: expense)
        }
        if categories.count > 2{
            let expense  = Expense(id: 0, name: "Test Expense", amount: 12.05, categories: [categories[2],categories[1]], dateTime: Date().timeIntervalSince1970)
                    DBHelper.shared.createNewExpense(expense: expense)
                }
        
        let expense = DBHelper.shared.fetchAllExpense()
        print(expense)
        DBHelper.shared.createNewCategory(category: Category(id: 0, name: "Testing11"))

    }

}

