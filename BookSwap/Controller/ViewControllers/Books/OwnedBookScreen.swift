//
//  OwnedBookScreen.swift
//  BookSwap
//
//  Created by RV on 10/5/19.
//  Copyright © 2019 RV. All rights reserved.
//

import UIKit
import CoreData
import SwipeCellKit

class OwnedBookScreen: UITableViewController {
    
    //Array which takes objects of OwnedBook
    var itemArray = [OwnedBook]()
    var otherUser = [OthersOwnedBook]()
    
    var usersBookShelf : String?
    
    //context of Core Data file
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    //Instances of other classes, which will be used to access the methods
    let databaseIstance = FirebaseDatabase.shared
    let authInstance = FirebaseAuth.sharedFirebaseAuth
    let coreDataClassInstance = CoreDataClass.sharedCoreData

    override func viewDidLoad() {
        super.viewDidLoad()
       
        //setting usersBookShelf equals to email of usersScreen
        //Whis was added inside ProfileScreen/prepareSegue
        usersBookShelf = authInstance.getUsersScreen()
        
        tableView.rowHeight = 80
        tableView.refreshControl = refresher
        
        //this disables the selection of row.
        //When user clicks on book, no selection will highlight any row
        tableView.allowsSelection = false
        if !authInstance.isItOtherUsersPage(userEmail: usersBookShelf!) {
            loadItems()
        } else {
            loadItemsOtherUser()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
    
        loadItems()
    }
    
    
    //MARK: TableView DataSource Methods
    
    //This method will be called when user selects or clicks on any row inside table
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //to create click animation
        tableView.deselectRow(at: indexPath, animated: true)
        
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("This is otherUser.count: \(otherUser.count)")
        return !authInstance.isItOtherUsersPage(userEmail: usersBookShelf!) ?  itemArray.count : otherUser.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "booksCell", for: indexPath) as! BooksTableViewCell
        
        if !authInstance.isItOtherUsersPage(userEmail: usersBookShelf!){
            
            cell.nameOfTheBook?.text = itemArray[indexPath.row].bookName
            cell.authorOfTheBook?.text = itemArray[indexPath.row].author
            cell.swap.isHidden = true
        
        } else {
            
            cell.nameOfTheBook?.text = otherUser[indexPath.row].bookName
            cell.authorOfTheBook?.text = otherUser[indexPath.row].author
            cell.swap.isHidden = true
        }
       
        cell.delegate = self
        return cell
    }

    
    //MARK: - Model Manipulation Methods
    
    func loadItems(with request: NSFetchRequest<OwnedBook> = OwnedBook.fetchRequest()) {
         do {
            if !authInstance.isItOtherUsersPage(userEmail: usersBookShelf!) {
             itemArray = try context.fetch(request)
            }
         } catch {
             print("Error fetching data from context \(error)")
         }
         
     }

    func loadItemsOtherUser(with request: NSFetchRequest<OthersOwnedBook> = OthersOwnedBook.fetchRequest()) {
        print("Inside the loadItemsOtherUser")
        do {
            
            //Making sure the database call is made only once to get data and load it into 'otherUser' array
            //Logic: if otherUser.count is equals to 0, that means function call (inside if statment) has not been made yet.
            if (otherUser.count == 0) {
                databaseIstance.getListOfOwnedBookOrWishList(usersEmail: usersBookShelf!, trueForOwnedBookFalseForWishList: true) { (dataDictionary) in

                    //this method sends the data recived in dictionary from Firestore, and place it inside "otherUser" array.
                    self.loadDataForOtherUser(dict: dataDictionary)
                }
            } else {

                //Once user searches anything in search bar, "requestForOthersOwnedBook" holds query.
                //context.fetch... will fetch result and store it inside otherUser array
                otherUser = try context.fetch(request)
            }
        } catch {
            print("Error fetching data from context \(error)")
        }
        
    }
    
    
    
    
    //Loads the data inside OthersOwnedBook array, which is received from Firestore
    func loadDataForOtherUser(dict : Dictionary<Int  , Dictionary<String  , Any>>) {
        
        //Clearing the data stored inside Core Data file
        coreDataClassInstance.resetOneEntitie(entityName: "OthersOwnedBook")
        
        //Clearing the array which holds objects of 'OthersWishList'
        otherUser.removeAll()
        
        for (_, data) in dict {
            
            //creating an object of OthersOwnedBook with the context of Core Data
            let newOwnedBook = OthersOwnedBook(context: context)
            
            //adding data from dictionary, data holds information such as bookName, author and status
            newOwnedBook.bookName = (data[databaseIstance.BOOKNAME_FIELD] as! String)
            newOwnedBook.author = (data[databaseIstance.AUTHOR_FIELD] as! String)
            newOwnedBook.status = data[databaseIstance.BOOK_STATUS_FIELD] as! Bool
            
            //Appending inside otherUser array
            otherUser.append(newOwnedBook)
        }
        
        //saving all the changes made in core data
        coreDataClassInstance.saveContext()
        
        //reloading the table view to show the latest result
        tableView.reloadData()
        
    }
    
    
    lazy var refresher: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.white
        refreshControl.addTarget(self, action: #selector(refreshItems), for: .valueChanged)
        
        return refreshControl
    }()
    
    
    @objc func refreshItems(){
        
        self.loadItems()
        let deadLine = DispatchTime.now() + .milliseconds(500)
        DispatchQueue.main.asyncAfter(deadline: deadLine) {
            self.refresher.endRefreshing()
        }
        self.tableView.reloadData()
    }
}



//MARK: Search

extension OwnedBookScreen: UISearchBarDelegate{
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        //search requests
        let searchRequest : NSFetchRequest<OwnedBook> = OwnedBook.fetchRequest()
        let searchRequestOtherUser : NSFetchRequest<OthersOwnedBook> = OthersOwnedBook.fetchRequest()

        //creating NSPredicate which finds keyword in bookName and author field
        let nsPredicate = NSPredicate(format: "(bookName CONTAINS[cd] %@) OR (author CONTAINS[cd] %@)", searchBar.text!, searchBar.text!)
        
        //once the result is recived, sorting it by bookName
        let nsSortDescriptor = [NSSortDescriptor(key: "bookName", ascending: true)]
        
        //Checking if otherUser is empty
        if (!authInstance.isItOtherUsersPage(userEmail: usersBookShelf!)) {
            
            //creating request for current user's own OwnedBook page
            searchRequest.predicate = nsPredicate
            searchRequest.sortDescriptors = nsSortDescriptor
            loadItems(with: searchRequest)
            
        } else {
            
            //creating reqest for other user's OwnedBook page
            searchRequestOtherUser.predicate = nsPredicate
            searchRequestOtherUser.sortDescriptors = nsSortDescriptor
            loadItemsOtherUser(with: searchRequestOtherUser)
        }
        
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count==0{
            //loadItems()
            
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
            if !authInstance.isItOtherUsersPage(userEmail: usersBookShelf!) {
                loadItems()
            } else {
                loadItemsOtherUser()
            }
            tableView.reloadData()
        }
    }
    
}

//MARK: SwipeCellKit
extension OwnedBookScreen: SwipeTableViewCellDelegate{
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        if (!authInstance.isItOtherUsersPage(userEmail: usersBookShelf!)) {
            guard orientation == .right else { return nil }
        } else {
            databaseIstance.addHoldingBook(bookOwnerEmail: usersBookShelf!, bookName: self.otherUser[indexPath.row].bookName!, bookAuthor: otherUser[indexPath.row].author!)
            return nil}
        
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            
            // handle action by updating model with deletion
            self.context.delete(self.itemArray[indexPath.row])
            
            //Using itemArray gettin name of book and book's author.
            self.databaseIstance.removeOwnedBook(bookName: self.itemArray[indexPath.row].bookName!, bookAuthor: self.itemArray[indexPath.row].author!)
            
            //Removing the data from itemArray
            self.itemArray.remove(at: indexPath.row)
            self.coreDataClassInstance.saveContext()
        }
        
        // customize the action appearance
        deleteAction.image = UIImage(named: "trash-icon")
        
        return [deleteAction]
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .destructive
        return options
    }
    
    
}
