//
//  DataStoreController.swift
//  HSCoredata
//
//  Created by Richard Good on 9/18/15.
//  Copyright © 2015 HannibalStudios. All rights reserved.
//

import Foundation
import CoreData

public class DataStoreController {


    public static var sharedInstance : DataStoreController  {
        return self
    }

    private var _managedObjectContext: NSManagedObjectContext

    public  var managedObjectContext: NSManagedObjectContext? {
        guard let coordinator = _managedObjectContext.persistentStoreCoordinator else {
            return nil
        }
        if coordinator.persistentStores.isEmpty {
            return nil
        }
        return _managedObjectContext
    }

    let managedObjectModel: NSManagedObjectModel
    let persistentStoreCoordinator: NSPersistentStoreCoordinator

 public    var error: NSError?

 public   func inContext(callback: NSManagedObjectContext? -> Void) {
        // Dispatch the request to our serial queue first and then back to the context queue.
        // Since we set up the stack on this queue it will have succeeded or failed before
        // this block is executed.
        dispatch_async(queue) {
            guard let context = self.managedObjectContext else {
                callback(nil)
                return
            }

            context.performBlock {
                callback(context)
            }
        }
    }

    private let queue: dispatch_queue_t

 public   init(modelUrl: NSURL, storeUrl: NSURL, concurrencyType: NSManagedObjectContextConcurrencyType = .MainQueueConcurrencyType) {

        guard let modelAtUrl = NSManagedObjectModel(contentsOfURL: modelUrl) else {
            fatalError("Error initializing managed object model from URL: \(modelUrl)")
        }
        managedObjectModel = modelAtUrl

        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        _managedObjectContext = NSManagedObjectContext(concurrencyType: concurrencyType)
        _managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]

        print("Initializing persistent store at URL: \(storeUrl.path!)")

        let dispatch_queue_attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0)
        queue = dispatch_queue_create("DataStoreControllerSerialQueue", dispatch_queue_attr)

        dispatch_async(queue) {
            do {
                try self.persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeUrl, options: options)
            } catch let error as NSError {
                print("Unable to initialize persistent store coordinator:", error)
                self.error = error
            } catch {
                fatalError()
            }
        }
    }
}
