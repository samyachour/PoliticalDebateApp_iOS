//
//  CoreDataService.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/20/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import CoreData
import UIKit

enum CoreDataConstants {
    static let progressEntity = "LocalProgress"
    static let starredEntity = "LocalStarred"
    static let debateEntity = "LocalDebate"
    static let pointEntity = "LocalPoint"
    static let primaryKeyAttribute = "primaryKey"
    static let debateRelationshipAttribute = "debate"
    static let progressRelationshipAttribute = "progress"
    static let container = "PoliticalDebateApp_iOS"
}

struct CoreDataService {

    private init() {}

    // MARK: - CRUD Operations

    static func fetchRecordsForEntity<T: NSManagedObject>(_ entity: String,
                                                          with predicate: NSPredicate? = nil,
                                                          unique: Bool = false) -> [T]? {
        guard CoreDataService.loadedStores else {
            NotificationBannerQueue.shared
                .enqueueBanner(using: NotificationBannerViewModel(style: .error,
                                                                  title: "Couldn't load local data.",
                                                                  subtitle: "Check device space, app permissions, or try restarting."))
            return nil
        }

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)

        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }

        let results = try? context.fetch(fetchRequest) as? [T]

        // If we should only receive 1 record w/ from the request but we get more than 1
        if let count = results?.count,
            unique,
            count > 1 {
            CoreDataService.showCoreDataCorruptedAlert()
        }

        return results
    }

    static func createRecord<T: NSManagedObject>() -> T {
        return T(context: context)
    }

    static func deleteRecord<T: NSManagedObject>(_ object: T) {
        context.delete(object)
    }

    // MARK: - Loading and saving context

    // So separate tasks can share objects across the same context and run synchronously on the same private background queue
    private static let context = CoreDataService.persistentContainer.newBackgroundContext()

    static func saveContext() {
        guard loadedStores else { return }

        do {
            try context.save()
        } catch {
            print(error)
            CoreDataService.showCoreDataSaveAlert()
        }
    }

    static let persistentContainer = NSPersistentContainer(name: CoreDataConstants.container)
    private static var loadedStores = false

    static func loadPersistentContainer(completion: @escaping (Error?) -> Void) {
        guard !loadedStores else {
            debugLog("Core Data stack has already been intialized")
            completion(nil)
            return
        }

        CoreDataService.persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */

                debugLog(error.localizedDescription)
                CoreDataService.showCoreDataLoadAlert()
                completion(GeneralError.alreadyHandled)
                return
            }
            debugLog("Core Data stack has been initialized with description: \(storeDescription)")

            CoreDataService.loadedStores = true
            completion(nil) // success
        })
    }

    // MARK: - Helpers

    static func showCoreDataLoadAlert() {
        let coreDataLoadAlert = UIAlertController(title: "Could not load local data",
                                                  message: "Try checking the app permissions. Otherwise your device might be out of space. Try restarting your app.",
                                                  preferredStyle: .alert)
        coreDataLoadAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))

        safelyShowAlert(alert: coreDataLoadAlert)
    }

    static func showCoreDataSaveAlert() {
        let coreDataSaveAlert = UIAlertController(title: "Could not save local data",
                                                  message: "Try checking the app permissions. Otherwise your device might be out of space. Try restarting your app.",
                                                  preferredStyle: .alert)
        coreDataSaveAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))

        safelyShowAlert(alert: coreDataSaveAlert)
    }

    static func showCoreDataCorruptedAlert() {
        let coreDataCorruptedAlert = UIAlertController(title: "Local data corrupted",
                                                       message: "Please delete and reinstall this app.",
                                                       preferredStyle: .alert)
        coreDataCorruptedAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))

        safelyShowAlert(alert: coreDataCorruptedAlert)
    }

}
