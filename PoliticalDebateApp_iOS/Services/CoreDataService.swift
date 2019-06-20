//
//  CoreDataService.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/20/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import CoreData
import UIKit

// TODO: Set up for parallel use alongside saving to backend

public final class CoreDataService {

    // MARK: - Core Data stack

    public static func loadPersistentContainer(completionHandler: @escaping (Error?) -> Void) {
        guard persistentContainer == nil else { return }
        let container = NSPersistentContainer(name: "PoliticalDebateApp_iOS")

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
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

                CoreDataService.showCoreDataAlert()
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            completionHandler(nil)
            CoreDataService.persistentContainer = container

            debugLog("Core Data stack has been initialized with description: \(storeDescription)")
        })
    }

    public static var persistentContainer: NSPersistentContainer?

    // MARK: Error handling

    private static func showCoreDataAlert() {
        let coreDataAlert = UIAlertController(title: "You are doing that too much",
                                              message: "Try checking the app permissions. Otherwise your device might be out of space.",
            preferredStyle: .alert)
        coreDataAlert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))

        if let appDelegate = AppDelegate.shared,
            let mainNavigationController = appDelegate.mainNavigationController,
            mainNavigationController.presentedViewController == nil {
            mainNavigationController.visibleViewController?.present(coreDataAlert, animated: true, completion: nil)
        }
    }

    // MARK: - Core Data Saving support

    public static func saveContext () {
        guard let context = CoreDataService.persistentContainer?.viewContext else { return }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                // You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
