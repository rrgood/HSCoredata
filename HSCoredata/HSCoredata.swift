//
//  HSCoredata.swift
//  HSCoredata
//
//  Created by Richard Good on 7/23/15.
//  Copyright © 2015 HannibalStudios. All rights reserved.
//

//import UIKit
import CoreData


public protocol Fetchable
{
    associatedtype FetchableType: NSManagedObject

    static func entityName() -> String
    static func objectsInContext(context: NSManagedObjectContext, predicate: NSPredicate?, sortedBy: [NSSortDescriptor]?, ascending: Bool) throws -> [FetchableType]
    static func singleObjectInContext(context: NSManagedObjectContext, predicate: NSPredicate?, sortedBy: [NSSortDescriptor]?, ascending: Bool) throws -> FetchableType?
    static func objectCountInContext(context: NSManagedObjectContext, predicate: NSPredicate?) -> Int
    static func fetchRequest(context: NSManagedObjectContext, predicate: NSPredicate?, sortedBy: [NSSortDescriptor]?, ascending: Bool) -> NSFetchRequest
    static func insertObject(context: NSManagedObjectContext) -> FetchableType?

}

public extension Fetchable where Self : NSManagedObject, FetchableType == Self
{

    static func singleObjectInContext(context: NSManagedObjectContext, predicate: NSPredicate? = nil, sortedBy: [NSSortDescriptor]? = nil, ascending: Bool = false) throws -> FetchableType?
    {
        let managedObjects: [FetchableType] = try objectsInContext(context, predicate: predicate, sortedBy: sortedBy, ascending: ascending)
        guard managedObjects.count > 0 else { return nil }

        return managedObjects.first
    }

    static func objectCountInContext(context: NSManagedObjectContext, predicate: NSPredicate? = nil) -> Int
    {
        let request = fetchRequest(context, predicate: predicate)
        let error: NSErrorPointer = nil
        let count = context.countForFetchRequest(request, error: error)
        guard error == nil else {
            NSLog("Error retrieving data %@, %@", error, error.debugDescription)
            return 0
        }

        return count
    }

    static func objectsInContext(context: NSManagedObjectContext, predicate: NSPredicate? = nil, sortedBy: [NSSortDescriptor]? = nil, ascending: Bool = false) throws -> [FetchableType]
    {
        let request = fetchRequest(context, predicate: predicate, sortedBy: sortedBy, ascending: ascending)
        let fetchResults = try context.executeFetchRequest(request)

        return fetchResults as! [FetchableType]
    }

    static func fetchRequest(context: NSManagedObjectContext, predicate: NSPredicate? = nil, sortedBy: [NSSortDescriptor]? = nil, ascending: Bool = false) -> NSFetchRequest
    {
        let request = NSFetchRequest()
        let entity = NSEntityDescription.entityForName(entityName(), inManagedObjectContext: context)
        request.entity = entity

        if predicate != nil {
            request.predicate = predicate
        }

        if (sortedBy != nil) {
            request.sortDescriptors = sortedBy
        }

        return request
    }
    
    static func distinctObjectsInContext(fieldsToFetch: [String],context: NSManagedObjectContext, predicate: NSPredicate? = nil, sortedBy: [NSSortDescriptor]? = nil, ascending: Bool = false) throws -> [AnyObject]
    {
        let request = fetchRequest(context, predicate: predicate, sortedBy: sortedBy, ascending: ascending)
        
        
        request.propertiesToFetch = fieldsToFetch
        request.resultType = NSFetchRequestResultType.DictionaryResultType
        request.returnsDistinctResults = true

        let fetchResults = try context.executeFetchRequest(request)
        
        return fetchResults
    }
    
    static func insertObject(context: NSManagedObjectContext) -> FetchableType? {
        guard let object = NSEntityDescription.insertNewObjectForEntityForName(Self.entityName(), inManagedObjectContext: context) as? FetchableType
            else { fatalError("Invalid Core Data Model.") }
        return object;
    }


    
}



public class DataStoreController {

    ///  A tuple value that describes the results of saving a managed object context.
    ///
    ///  - parameter success: A boolean value indicating whether the save succeeded. It is `true` if successful, otherwise `false`.
    ///  - parameter error:   An error object if an error occurred, otherwise `nil`.
    public typealias ContextSaveResult = (success: Bool, error: NSError?)

    ///  Describes a child managed object context.
    public typealias ChildManagedObjectContext = NSManagedObjectContext


    public static let sharedInstance = DataStoreController()

    init(){

    }

    private var _managedObjectContext: NSManagedObjectContext!
    private var managedObjectModel: NSManagedObjectModel!
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator!
    private var queue: dispatch_queue_t!

    public  var managedObjectContext: NSManagedObjectContext? {
        guard let coordinator = _managedObjectContext.persistentStoreCoordinator else {
            return nil
        }
        if coordinator.persistentStores.isEmpty {
            return nil
        }
        return _managedObjectContext
    }


    public var error: NSError?

    public func inContext(callback: NSManagedObjectContext? -> Void) {
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


    
    public func initSharedInstance(modelUrl: NSURL, storeUrl: NSURL, useWAL:Bool = true, concurrencyType: NSManagedObjectContextConcurrencyType = .MainQueueConcurrencyType) {

        guard let modelAtUrl = NSManagedObjectModel(contentsOfURL: modelUrl) else {
            fatalError("Error initializing managed object model from URL: \(modelUrl)")
        }
        managedObjectModel = modelAtUrl

        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        _managedObjectContext = NSManagedObjectContext(concurrencyType: concurrencyType)
        _managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        var options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true,
            NSSQLitePragmasOption: ["journal_mode": "delete"]
        ]
        if useWAL {
            options[NSSQLitePragmasOption] = nil
        }

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
    
    public func replaceDataStore(storeUrl: NSURL,useWAL:Bool = false){
        _managedObjectContext.reset()
        var options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true,
            NSSQLitePragmasOption: ["journal_mode": "delete"]
        ]
        if useWAL {
            options[NSSQLitePragmasOption] = nil
        }
    
        let dispatch_queue_attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0)
        queue = dispatch_queue_create("DataStoreControllerSerialQueue", dispatch_queue_attr)
        
        dispatch_async(queue) {
            do {
                try self.persistentStoreCoordinator.removePersistentStore(self.persistentStoreCoordinator.persistentStores[0])
                try self.persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeUrl, options: options)
            } catch let error as NSError {
                print("Unable to initialize persistent store coordinator:", error)
                self.error = error
            } catch {
                fatalError()
            }
        }
    }

    ///  Attempts to commit unsaved changes to registered objects to the specified context's parent store.
    ///  This method is performed *asynchronously* in a block on the context's queue.
    ///  If the context returns `false` from `hasChanges`, this function returns immediately.
    ///
    ///  - parameter context:    The managed object context to save.
    ///  - parameter completion: The closure to be executed when the save operation completes.
    public func saveContext(context: NSManagedObjectContext, completion: (ContextSaveResult) -> Void) {
        if !context.hasChanges {
            completion((true, nil))
            return
        }

        context.performBlock { () -> Void in
            var error: NSError?
            let success: Bool
            do {
                try context.save()
                success = true
            } catch let error1 as NSError {
                error = error1
                success = false
            } catch {
                fatalError()
            }

            if !success {
                print("*** ERROR: [\(#line)] \(#function) Could not save managed object context: \(error)")
            }

            completion((success, error))
        }
    }



    // MARK: Child contexts

    ///  Creates a new child managed object context with the specified concurrencyType and mergePolicyType.
    ///
    ///  - parameter concurrencyType: The concurrency pattern with which the managed object context will be used.
    ///                          The default parameter value is `.MainQueueConcurrencyType`.
    ///  - parameter mergePolicyType: The merge policy with which the manged object context will be used.
    ///                          The default parameter value is `.MergeByPropertyObjectTrumpMergePolicyType`.
    ///
    ///  - returns: A new child managed object context initialized with the given concurrency type and merge policy type.
    public func childManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType = .MainQueueConcurrencyType,
        mergePolicyType: NSMergePolicyType = .MergeByPropertyObjectTrumpMergePolicyType) -> ChildManagedObjectContext {

            let childContext = NSManagedObjectContext(concurrencyType: concurrencyType)
            childContext.parentContext = managedObjectContext
            childContext.mergePolicy = NSMergePolicy(mergeType: mergePolicyType)
            return childContext
    }



    // MARK: Entity access
    

    ///  Returns the entity with the specified name from the managed object model associated with the specified managed object context’s persistent store coordinator.
    ///
    ///  - parameter name:    The name of an entity.
    ///  - parameter context: The managed object context to use.
    ///
    ///  - returns: The entity with the specified name from the managed object model associated with context’s persistent store coordinator.
    public func entity(name name: String, context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entityForName(name, inManagedObjectContext: context)!
    }


    ///  Deletes the objects from the specified context.
    ///  When changes are committed, the objects will be removed from their persistent store.
    ///  You must save the context after calling this function to remove objects from the store.
    ///
    ///  - parameter objects: The managed objects to be deleted.
    ///  - parameter context: The context to which the objects belong.
    public func deleteObjects <T: NSManagedObject>(objects: [T], egq context: NSManagedObjectContext) {

        if objects.count == 0 {
            return
        }

        context.performBlockAndWait { () -> Void in
            for each in objects {
                context.deleteObject(each)
            }
        }
    }


    // MARK: Printable

    /// :nodoc:
    public var description: String {
        get {
            return "<\(String(DataStoreController.self)): model=\(managedObjectModel)>"
        }
    }

}



