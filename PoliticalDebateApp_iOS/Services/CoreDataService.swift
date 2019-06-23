//
//  CoreDataService.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/20/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import CoreData
import UIKit

public enum CoreDataConstants {
    static let progressEntity = "LocalProgress"
    static let starredEntity = "LocalStarred"
    static let debateEntity = "LocalDebate"
    static let pointEntity = "LocalPoint"
    static let primaryKeyAttribute = "primaryKey"
    static let debateRelationshipAttribute = "debate"
    static let progressRelationshipAttribute = "progress"
    static let pointLabelAttribute = "label"
    static let container = "PoliticalDebateApp_iOS"
}

public final class CoreDataService {

    // MARK: CRUD Operations

    public static func fetchRecordsForEntity<T: NSManagedObject>(_ entity: String,
                                                                 in managedObjectContext: NSManagedObjectContext,
                                                                 with predicate: NSPredicate? = nil,
                                                                 unique: Bool = false) -> [T]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)

        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }

        let results = try? managedObjectContext.fetch(fetchRequest) as? [T]

        // If we should only receive 1 record w/ from the request but we get more than 1
        if let count = results?.count,
            unique,
            count > 1 {
            CoreDataService.showCoreDataCorruptedAlert()
        }

        return results
    }

    // MARK: Loading and saving context

    public static let persistentContainer = NSPersistentContainer(name: CoreDataConstants.container)
    private static var loadedStores = false

    public static func loadPersistentContainer(completionHandler: @escaping (Error?) -> Void) {
        guard !loadedStores else {
            debugLog("Core Data stack has already been intialized")
            completionHandler(nil)
            return
        }

        CoreDataService.persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                // You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                completionHandler(error)

                CoreDataService.showCoreDataLoadAlert()
            }
            debugLog("Core Data stack has been initialized with description: \(storeDescription)")

            CoreDataService.loadedStores = true
            completionHandler(nil) // success
        })
    }

    public static func saveContext () {
        let context = CoreDataService.persistentContainer.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                CoreDataService.showCoreDataSaveAlert()
            }
        }
    }

    // MARK: Helpers

    public static func showCoreDataLoadAlert() {
        let coreDataLoadAlert = UIAlertController(title: "Could not load local data",
                                                  message: "Try checking the app permissions. Otherwise your device might be out of space.",
                                                  preferredStyle: .alert)
        coreDataLoadAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))

        safelyShowAlert(alert: coreDataLoadAlert)
    }

    public static func showCoreDataSaveAlert() {
        let coreDataSaveAlert = UIAlertController(title: "Could not save local data",
                                                  message: "Try checking the app permissions. Otherwise your device might be out of space.",
                                                  preferredStyle: .alert)
        coreDataSaveAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))

        safelyShowAlert(alert: coreDataSaveAlert)
    }

    public static func showCoreDataCorruptedAlert() {
        let coreDataCorruptedAlert = UIAlertController(title: "Local data corrupted",
                                                       message: "Please delete and reinstall this app.",
                                                       preferredStyle: .alert)
        coreDataCorruptedAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))

        safelyShowAlert(alert: coreDataCorruptedAlert)
    }

}
