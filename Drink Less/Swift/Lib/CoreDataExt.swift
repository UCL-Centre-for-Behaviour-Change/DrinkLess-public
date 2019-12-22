//
//  CoreDataExt.swift
//  drinkless
//
//  Created by Hari Karam Singh on 28/02/2019.
// Copyright © 2019 UCL. All rights reserved.
//

import Foundation

extension NSManagedObject {
        
    //////////////////////////////////////////////////////////
    // MARK: - Class Methods
    //////////////////////////////////////////////////////////

    class func create(in context:NSManagedObjectContext) -> Self {
        let eName = String(describing: self)
        let entity = NSEntityDescription.entity(forEntityName: eName, in: context)!
        let new = self.init(entity: entity, insertInto: context)
        return new
    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Properties
    //////////////////////////////////////////////////////////
    
    internal var server:DataServer {
        return DataServer.shared
    }
    
    //////////////////////////////////////////////////////////
    // MARK: - Public Methods
    //////////////////////////////////////////////////////////
}
