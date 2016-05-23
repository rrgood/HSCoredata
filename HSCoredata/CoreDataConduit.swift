//
//  CoreDataConduit.swift
//  HSCoredata
//
//  Created by Richard Good on 9/18/15.
//  Copyright © 2015 HannibalStudios. All rights reserved.
//

import Foundation
import CoreData

class CoreDataConduit {


    class var sharedInstance : CoreDataConduit {
        struct Static {
            static let instance : CoreDataConduit = CoreDataConduit()
        }
        return Static.instance
    }

    class func debugString(theString:String) {
        print("CoreDataConduit: \(theString)")
    }

    class func returnChildManagedObjectContext()->NSManagedObjectContext?{

        if let myManagedObjectContext = self.returnMainManagedObjectContext() {

            let childManagedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)

            childManagedObjectContext.parentContext = myManagedObjectContext

            return childManagedObjectContext
        }

        return nil
    }

    class func returnMyManagedObjectContext ()->NSManagedObjectContext? {

        self.debugString("returnMyManagedObjectContext")

        if let myManagedObjectContext = NSThread.currentThread().threadDictionary.objectForKey("threadManagedObjectContext") as? NSManagedObjectContext {

            return myManagedObjectContext
        }else{

            if let newManagedObjectContext = self.returnChildManagedObjectContext() {

                NSThread.currentThread().threadDictionary.setObject(newManagedObjectContext, forKey: "threadManagedObjectContext")

                return newManagedObjectContext
            }
        }

        return nil
    }

    class func returnMainManagedObjectContext ()->NSManagedObjectContext? {

//        if let myManagedObjectContext = NestedSingleton.sharedInstance.myManagedObjectContext as? NSManagedObjectContext {
//
//            return myManagedObjectContext
//        }

        CoreDataConduit.debugString("ManagedObjectContext Doesn't exist")

        return nil
    }

//    class func fetchNumberOfResults(theEntity:String, withQuery theQuery:String? = nil, withArgument theArgument:CVarArgType? = nil) -> Int?{
//
//        if let myManagedObjectContext = self.returnMyManagedObjectContext()  {
//
//            if let theFetchRequest = fetchRequest(theEntity, withQuery:theQuery, withArgument:theArgument) {
//
//                return self.countFromFetchRequest(theFetchRequest)
//            }
//        }
//
//        return nil
//    }

//    class func countFromFetchRequest(fetchRequest:NSFetchRequest)->Int{
//
//        var returnResults = 0
//
//        if let myManagedObjectContext = self.returnMyManagedObjectContext(){
//
//            fetchRequest.resultType = NSFetchRequestResultType.CountResultType
//
//            var theError:NSError? = nil
//
//            myManagedObjectContext.performBlockAndWait{
//
//                if let retrievedResults = myManagedObjectContext.executeFetchRequest(fetchRequest, error:&theError) as? Array<NSNumber> {
//
//                    if retrievedResults.count > 0 {
//
//                        returnResults = retrievedResults[0].integerValue
//                    }
//                }
//
//                if let myErrorDescription = theError?.description {
//
//                    self.debugString("theError: \(myErrorDescription)")
//                }
//            }
//        }
//
//        return returnResults
//    }

//    class func resultsFromFetchRequest(fetchRequest:NSFetchRequest)->Array<NSManagedObject>?{
//
//        var returnResults = Array<NSManagedObject>()
//
//        if let myManagedObjectContext = self.returnMyManagedObjectContext(){
//
//            self.debugString("resultsFromFetchRequest: Found managed object context")
//
//            var theError:NSError? = nil
//
//            myManagedObjectContext.performBlockAndWait{
//
//                self.debugString("resultsFromFetchRequest: Dispatching asynchronously.")
//
//                if let retrievedResults = myManagedObjectContext.executeFetchRequest(fetchRequest, error:&theError) as? Array<NSManagedObject> {
//
//                    self.debugString("resultsFromFetchRequest: Got results from fetch request: \(retrievedResults.count)")
//
//                    returnResults = retrievedResults
//                }
//
//                if let myErrorDescription = theError?.description {
//
//                    self.debugString("resultsFromFetchRequest: theError: \(myErrorDescription)")
//                }
//            }
//        }
//
//        return returnResults
//    }

    class func getObjectFromId(theId:NSManagedObjectID)->NSManagedObject?{

        if let myManagedObjectContext = self.returnMyManagedObjectContext() {

            return myManagedObjectContext.objectWithID(theId)
        }

        return nil
    }

//    class func fetchResults(theEntity:NSString, withQuery theQuery:String? = nil, withArgument theArgument:CVarArgType? = nil, orderedBy orderKey:String? = nil) -> Array<NSManagedObject>? {
//
//        var returnArray:Array<NSManagedObject>? = nil
//
//        if let theFetchRequest = fetchRequest(theEntity, withQuery:theQuery, withArgument:theArgument, orderedBy:orderKey) {
//
//            self.debugString("Created fetch request for entity: \(theEntity)")
//
//            returnArray = resultsFromFetchRequest(theFetchRequest)
//        }
//
//        self.debugString("Found: \(returnArray?.count)")
//
//        return returnArray
//    }

//    class func fetchRequest(theEntity:NSString, withQuery theQuery:String? = nil, withArgument theArgument:CVarArgType? = nil, orderedBy orderKey:String? = nil) -> NSFetchRequest? {
//
//        let fetchRequest = NSFetchRequest(entityName: theEntity as String)
//
//        if theQuery != nil && theArgument != nil {
//
//            if let stringArg = theArgument as? NSString {
//
//                fetchRequest.predicate = NSPredicate(format: "\(theQuery!) = \"\(theArgument!)\"")
//            }else{
//
//                if let theArgumentInt = theArgument as? Int {
//
//                    let theArgumentNum = NSNumber(integer: theArgumentInt)
//
//                    fetchRequest.predicate = NSPredicate(format: "\(theQuery!) = \(theArgumentNum)")
//                }else{
//
//                    fetchRequest.predicate = NSPredicate(format: "\(theQuery!) = \(theArgument!)")
//                }
//            }
//        }
//
//        fetchRequest.resultType = NSFetchRequestResultType.ManagedObjectResultType
//
//        if orderKey != nil {
//            let sortDescriptor = NSSortDescriptor(key: orderKey!, ascending: true)
//            fetchRequest.sortDescriptors = [sortDescriptor]
//        }
//
//        return fetchRequest
//    }

//    class func deleteAllFromEntity(theEntity:NSString){
//
//        if let returnArray = fetchResults(theEntity) {
//
//            for anObject in returnArray {
//
//                if anObject.managedObjectContext != nil {
//
//                    anObject.managedObjectContext!.deleteObject(anObject)
//                }
//            }
//        }
//    }
//
//    class func deleteAllWith(attribute:CVarArgType, forName attributeName:String, within entityName:String){
//
//        if let fetchRequest = self.fetchRequest(entityName, withQuery: attributeName, withArgument: attribute) {
//
//            if let fetchResults = resultsFromFetchRequest(fetchRequest){
//
//                for anObject in fetchResults {
//
//                    if anObject.managedObjectContext != nil {
//
//                        anObject.managedObjectContext!.deleteObject(anObject)
//                    }
//                }
//            }
//        }
//    }
//
//    class func isThisAttribute(attribute:CVarArgType, forName attributeName:String, uniqueWithin entityName:String)->Bool{
//
//        if let fetchRequest = self.fetchRequest(entityName, withQuery: attributeName, withArgument: attribute){
//
//            if let fetchResults = resultsFromFetchRequest(fetchRequest){
//
//                if fetchResults.count > 0 {
//
//                    return false
//                }
//            }
//        }
//
//        return true
//    }


//    class func saveContext(theContext:NSManagedObjectContext? = nil){
//
//        if theContext != nil {
//
//            if theContext!.hasChanges {
//
//                var saveError:NSError? = nil
//
//                CoreDataConduit.debugString("Saving supplied context")
//                theContext!.save(&saveError)
//
//                if let errorDescription = saveError?.description {
//
//                    CoreDataConduit.debugString("privateSaveError: \(errorDescription)")
//                }
//            }
//        }else if let myManagedObjectContext = self.returnMyManagedObjectContext() {
//
//            if myManagedObjectContext.hasChanges {
//
//                var saveError:NSError? = nil
//
//                CoreDataConduit.debugString("Saving main context")
//                myManagedObjectContext.save(&saveError)
//
//                if let errorDescription = saveError?.description {
//
//                    CoreDataConduit.debugString("mainContextsaveError: \(errorDescription)")
//                }
//            }
//        }
//    }
}
