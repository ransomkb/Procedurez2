//
//  MasterViewController.swift
//  Procedurez
//
//  Created by Ransom Barber on 9/4/15.
//  Copyright (c) 2015 Ransom Barber. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISplitViewControllerDelegate {

    @IBOutlet weak var settingsButton: UIBarButtonItem!
    
    // Determines whether the master view is shown first or not on an iPhone
    private var collapseDetailViewController = true
    
    var alertMessage: String?
    
    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    
    let masterCellIdentifier = "TableViewCell"
    
    lazy var temporaryContext: NSManagedObjectContext? = {
        // Set the temporary context
        var temporaryContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        temporaryContext.persistentStoreCoordinator = CoreDataStackManager.sharedInstance().managedObjectContext!.persistentStoreCoordinator
        return temporaryContext
    }()
    
    // Lazy computed property returning a fetched results controller for Step entities sorted by title.
    lazy var shareFetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Step")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.temporaryContext!,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        }()
    
    @IBAction func openSettings(sender: AnyObject) {
        print("openSettings Action Occurring. Preparing to Show MetaTableViewController")
        
        let masterNavigationController = splitViewController!.viewControllers[0] as! UINavigationController
        let controller = self.storyboard?.instantiateViewControllerWithIdentifier("MetaTableViewController") as! MetaTableViewController
        masterNavigationController.pushViewController(controller, animated: true)
    }
    
    // seems to be removed from xcode 8
    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Master View Did Load: Start")
        
        splitViewController?.delegate = self
        
        if let fetched = self.fetchedResultsController.fetchedObjects {
            if fetched.count <= 0 {
                insertNewObject(self)
            } else {
                print("Fetched objects is more than 0")
            }
        }
        
        if let _ = self.fetchedResultsController.fetchedObjects?.isEmpty {
            print("Still empty")
        }
        
        self.settingsButton.title = NSString(string: "\u{2699}") as String
        if let font = UIFont(name: "Helvetica", size: 22.0) {
            self.settingsButton.setTitleTextAttributes([NSFontAttributeName: font], forState: UIControlState.Normal)
        }
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        
        let leftBarButtonItems: [UIBarButtonItem] = [settingsButton, self.editButtonItem()]
        let rightBarButtonItems: [UIBarButtonItem] = [addButton]
        
        self.navigationItem.leftBarButtonItems = leftBarButtonItems
        self.navigationItem.rightBarButtonItems = rightBarButtonItems
        
        if let split = self.splitViewController {
            print("is a splitviewcontroller")
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
            
            if let detailController = self.detailViewController {
                detailController.managedObjectContext = self.managedObjectContext
                
                if let fetched = self.fetchedResultsController.fetchedObjects {
                    print("master fetcher has objects")
                    let step = fetched[0] as? Step
                    print("Have a first step")
                    detailController.detailItem = step
                }
            }
        }
        
        // Make the style easier on the eyes by removing the separator.
        tableView.separatorStyle = .None
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
        
        checkInstructions()
        
        print("Master View Did Load: End")
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
        print("Master view will appear: start")
        
        print("Reloading data in Master View")
        self.tableView.reloadData()
        print("Master view will appear: end")
        
    }

    func insertNewObject(sender: AnyObject) {
        print("Inserting new Procedure object")
        
        // Set the context and entity info.
        let context = self.fetchedResultsController.managedObjectContext
        let entity = self.fetchedResultsController.fetchRequest.entity!
        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context) 
        
        let editName = "Tap to Edit Name"
        let editDetails = "Add a short description"
        
        newManagedObject.setValue(editName, forKey: "title")
        newManagedObject.setValue(editDetails, forKey: "details")
             
        // Save the context.
        var error: NSError? = nil
        do {
            try context.save()
        } catch let error1 as NSError {
            error = error1
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            print("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
    }

    func checkInstructions() {
        if let _ = fetchedResultsController.fetchedObjects {
            for p in fetchedResultsController.fetchedObjects as! [Step] {
                
                if p.title == "How to Use This App" {
                    print("Instructions are already loaded.")
                    return
                }
            }
        }
        
        // Load the HowTo Instructions if necessary.
        let jsonData = NetLoader.Caches.procedureCache.dataWithIdentifier("LoadMe")!
        print("Master has jsonData from LoadMe file: ") // \(jsonData)
        NetLoader.sharedInstance().loadHowTo(jsonData) { (success, errorString) -> Void in
            if success {
                let successMessage = "Master: Could load jsonData into Core Data"
                print(successMessage)
                self.alertMessage = successMessage
                self.alertUser()
            } else {
                let errorMessage = "Master: Error loading jsonData: \(errorString)"
                print(errorMessage)
                self.alertMessage = errorMessage
                self.alertUser()
            }
        }
    }
    
    
    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("Preparing for Segue to Detail")
        if segue.identifier == "showDetail" {
            print("Have a segue identifier called showDetail")
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Step
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.managedObjectContext = self.managedObjectContext
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
                
                print("Destination view controller set up")
            }
        }
    }

    // MARK: - Table View
    // maybe won't use
//    func configureTableView() {
//        tableView.rowHeight = UITableViewAutomaticDimension
//        tableView.estimatedRowHeight = 80.0
//    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] 
        
        print("Number of Rows in Section: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        print("\(tableView.rowHeight)")
        return 44.0 //tableView.rowHeight
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
        cell.textLabel?.text = object.valueForKey("title")!.description
        
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let context = self.fetchedResultsController.managedObjectContext
            context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
                
            var error: NSError? = nil
            do {
                try context.save()
            } catch let error1 as NSError {
                error = error1
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                print("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        // Set the background color of each cell.
        cell.backgroundColor = colorForIndex(indexPath.row)
        cell.textLabel?.textColor = UIColor.whiteColor()
    }
    
    // Allow the detail view to be shown.
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        collapseDetailViewController = false
    }
    

//    func configureCell(indexPath: NSIndexPath) -> TableViewCell {
//        
//        // Dequeue custom cell as TableViewCell.
//        if let cell: TableViewCell = tableView.dequeueReusableCellWithIdentifier(masterCellIdentifier, forIndexPath: indexPath) as? TableViewCell {
//            print("Cell is a TableViewCell")
//                        
//            
//        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
//        let text = object.valueForKey("title")!.description
//        if let label = cell.nameLabel {
//            
//            print("Have a namelabel for cell")
//            label.text = text
//        } else {
//            print("no namelabel in cell")
//            cell.textLabel?.text = text
//        }
//        
//        return cell
//        }
//        let oldCell = TableViewCell()
//        return oldCell
//    }
    
    // MARK: - Split view delegate
    
    // Ensure the first view on the iPhone is the master view when this returns true.
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        return collapseDetailViewController
    }
    
    // MARK: - Table view delegate
    
    // Return a color for the index.
    func colorForIndex(index: Int) -> UIColor {
        
        // Determine the number of items.
        let itemCount = tableView(tableView, numberOfRowsInSection: 0)
        
        // Calculate the amount of green to use.
        let value = (CGFloat(index) / CGFloat(itemCount)) * 0.6
        
        return UIColor(red: 0.0, green: value, blue: 0.9, alpha: 1.0)
    }
    
    

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController {
        print("Accessing the Master fetched results controller")
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("Step", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        //_ = [sortDescriptor]
        
        let predicate = NSPredicate(format: "parent == nil")
        
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
    	var error: NSError? = nil
    	do {
            try _fetchedResultsController!.performFetch()
        } catch let error1 as NSError {
            error = error1
    	     // Replace this implementation with code to handle the error appropriately.
    	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             print("Unresolved error \(error), \(error!.userInfo)")
    	     abort()
    	}
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController? = nil

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
            case .Insert:
                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            case .Delete:
                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            default:
                return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update: break
            //_ = configureCell(indexPath!)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
//        default:
//            return
        }

    }

//    func controller(controller: NSFetchedResultsController, didChangeObject anObject: NSManagedObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
//            }

    // IMPORTANT: not using this because wish to try refreshing for background color.
//    func controllerDidChangeContent(controller: NSFetchedResultsController) {
//        self.tableView.endUpdates()
//    }

    
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
         // In the simplest, most efficient, case, reload the table view.
        // IMPORTANT: added the end updates as no changes immediately when adding otherwise.
         self.tableView.endUpdates()
         self.tableView.reloadData()
     }
    
    // MARK: - Misc
    
    // IMPORTANT: finish this; maybe use, maybe not.
//    func createJSONData(procedure: Procedure) {
//        if let indexPath = self.tableView.indexPathForSelectedRow {
//            let selectedStep = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Step
//            // Instantiate a fetch request for all the Steps of the selected Procedure.
//            let fetchRequest = NSFetchRequest(entityName: "Procedure")
//            let predicate = NSPredicate(format: "title == %@", selectedStep.title)
//            fetchRequest.predicate = predicate
//            
//            do {
//                try temporaryContext?.executeFetchRequest(fetchRequest)
//            } catch {
//                print("Unable to fetch the Step entities for sharing due to error: \(error)")
//            }
//        }
//    }
    
    // IMPORTANT: probably will not use
    // Use UIAlertController to keep user informed.
    func alertUser() {
        
        // Create an instance of alert controller.
        let alertController = UIAlertController(title: "Add Procedure", message: self.alertMessage, preferredStyle: .Alert)
        
        
        // Set up an OK action button on alert.
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        // Add OK action button to alert.
        alertController.addAction(okAction)
        
        // Dispatch alert to main queue.
        dispatch_async(dispatch_get_main_queue(), {
            
            // Present alert controller.
            self.presentViewController(alertController, animated: true, completion: nil)
        })
    }
    
}

