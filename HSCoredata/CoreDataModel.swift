//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://www.jessesquires.com/JSQCoreDataKit
//
//
//  GitHub
//  https://github.com/jessesquires/JSQCoreDataKit
//
//
//  License
//  Copyright (c) 2015 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

import Foundation
import CoreData


///  An instance of `CoreDataModel` represents a Core Data model.
///  It provides the model and store URLs as well as functions for interacting with the store.
public struct CoreDataModel: CustomStringConvertible {

    // MARK: Properties

    ///  The name of the Core Data model resource.
    public let name: String

    ///  The bundle in which the model is located.
    public let bundle: NSBundle

    ///  The file URL specifying the directory in which the store is located.
    public let storeDirectoryURL: NSURL

    ///  The file URL specifying the full path to the store.
    public var storeURL: NSURL {
        get {
            return storeDirectoryURL.URLByAppendingPathComponent(databaseFileName)
        }
    }

    ///  The file URL specifying the model file in the bundle specified by `bundle`.
    public var modelURL: NSURL {
        get {
            // check for both versioned momd and unversioned mom models.
            let url = bundle.URLForResource(name, withExtension: "momd")
            if let modelURL = url{
                return modelURL
            }
            else {
                let url = bundle.URLForResource(name, withExtension: "mom")
                if let modelURL = url{
                    return modelURL
                }
            }
            assert(url != nil, "*** Error loading resource for model named \(name) at url: \(url)")
            return url!
        }
    }

    ///  The database file name for the store.
    public var databaseFileName: String {
        get {
            return name + ".sqlite"
        }
    }

    ///  The managed object model for the model specified by `name`.
    public var managedObjectModel: NSManagedObjectModel {
        get {
            let model = NSManagedObjectModel(contentsOfURL: modelURL)
            assert(model != nil, "*** Error loading managed object model at url: \(modelURL)")
            return model!
        }
    }

    ///  Queries the meta data for the persistent store specified by the receiver and returns whether or not a migration is needed.
    ///  Returns `true` if the store requires a migration, `false` otherwise.
    public var modelStoreNeedsMigration: Bool {
        get {
            var error: NSError?

            do {
//                let sourceMetaData = try NSPersistentStoreCoordinator.metadataForPersistentStoreOfType(nil, URL: storeURL)
                let sourceMetaData = try NSPersistentStoreCoordinator.metadataForPersistentStoreOfType( NSSQLiteStoreType, URL: storeURL, options: [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true])

                return !managedObjectModel.isConfiguration(nil, compatibleWithStoreMetadata: sourceMetaData)
            } catch let error1 as NSError {
                error = error1
            }
            print("*** \(String(CoreDataModel.self)) ERROR: [\(#line)] \(#function) Failure checking persistent store coordinator meta data: \(error)")
            return false
        }
    }

    // MARK: Initialization

    ///  Constructs new `CoreDataModel` instance with the specified name and bundle.
    ///
    ///  - parameter name:              The name of the Core Data model.
    ///  - parameter bundle:            The bundle in which the model is located. The default parameter value is `NSBundle.mainBundle()`.
    ///  - parameter storeDirectoryURL: The directory in which the model is located. The default parameter value is the user's documents directory.
    ///
    ///  - returns: A new `CoreDataModel` instance.
    public init(name: String, bundle: NSBundle = NSBundle.mainBundle(), storeDirectoryURL: NSURL = documentsDirectoryURL()) {
        self.name = name
        self.bundle = bundle
        self.storeDirectoryURL = storeDirectoryURL
    }

    // MARK: Methods

    ///  Removes the existing model store specfied by the receiver.
    ///
    ///  - returns: A tuple value containing a boolean to indicate success and an error object if an error occurred.
    public func removeExistingModelStore() -> (success: Bool, error: NSError?) {
        var error: NSError?
        let fileManager = NSFileManager.defaultManager()

        if let storePath = storeURL.path {
            if fileManager.fileExistsAtPath(storePath) {
                let success: Bool
                do {
                    try fileManager.removeItemAtURL(storeURL)
                    success = true
                } catch let error1 as NSError {
                    error = error1
                    success = false
                }
                if !success {
                    print("*** \(String(CoreDataModel.self)) ERROR: [\(#line)] \(#function) Could not remove model store at url: \(error)")
                }
                return (success, error)
            }
        }

        return (false, nil)
    }

    // MARK: Printable

    /// :nodoc:
    public var description: String {
        get {
            return "<\(String(CoreDataModel.self)): name=\(name), needsMigration=\(modelStoreNeedsMigration), databaseFileName=\(databaseFileName), modelURL=\(modelURL), storeURL=\(storeURL)>"
        }
    }

}

// MARK: Private

private func documentsDirectoryURL() -> NSURL {
    var error: NSError?
    let url: NSURL?
    do {
        url = try NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
    } catch let error1 as NSError {
        error = error1
        url = nil
    }
    assert(url != nil, "*** Error finding documents directory: \(error)")
    return url!
}
