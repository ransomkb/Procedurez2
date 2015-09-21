//
//  Procedure.swift
//  Procedurez
//
//  Created by Ransom Barber on 9/7/15.
//  Copyright (c) 2015 Ransom Barber. All rights reserved.
//

import Foundation
import CoreData

@objc(Procedure)

class Procedure: NSManagedObject {
    
    @NSManaged var title: String
    @NSManaged var details: String
    
    @NSManaged var steps: [Step]
    
    // Initiate the parent class with the entity and context.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // Use a convenience initializer.
    init(context: NSManagedObjectContext) {
        
        // Fetch the entity named Pin.
        let entity =  NSEntityDescription.entityForName("Procedure", inManagedObjectContext: context)!
        
        // Initiate the parent class with the entity and context.
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // Use a convenience initializer to prepare properties.
    init(title: String, context: NSManagedObjectContext) {
        
        // Fetch the entity named Pin.
        let entity =  NSEntityDescription.entityForName("Procedure", inManagedObjectContext: context)!
        
        // Initiate the parent class with the entity and context.
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.title = title
        details = ""
        
        print("Procedure init with title, name: \(self.title)")
    }
}

