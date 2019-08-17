//
//  StarredCoreDataAPI.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/22/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import CoreData

final class StarredCoreDataAPI {

    // MARK: - Core data

    // So all our tasks run on the same private background queue when updating/retreiving records
    private static let context = CoreDataService.persistentContainer.newBackgroundContext()
    private static func saveContext() {
        do {
            try StarredCoreDataAPI.context.save()
        } catch {
            CoreDataService.showCoreDataSaveAlert()
        }
    }

    // MARK: - CRUD operations

    static func starOrUnstarDebate(_ debatePrimaryKey: PrimaryKey, unstar: Bool = false) {
        defer { saveContext() }

        let localStarred = StarredCoreDataAPI.loadStarredDebates()

        // Explicit type for generic method
        let localDebateRecords: [LocalDebate]? = CoreDataService
            .fetchRecordsForEntity(CoreDataConstants.debateEntity,
                                   in: StarredCoreDataAPI.context,
                                   with: StarredCoreDataAPI.debatePrimaryKeyPredicate(debatePrimaryKey),
                                   unique: true)
        let localDebate = localDebateRecords?.first ?? LocalDebate(context: StarredCoreDataAPI.context)
        localDebate.primaryKey = Int32(debatePrimaryKey)
        localDebate.starred = localStarred

        if unstar {
            localStarred.removeFromStarredList(localDebate)
        } else {
            localStarred.addToStarredList(localDebate)
        }
    }

    static func loadAllStarred() -> Starred? {
        defer { saveContext() }

        let localStarred = StarredCoreDataAPI.loadStarredDebates()

        return Starred(from: localStarred)
    }

    static func clearAllStarred() {
        defer { saveContext() }

        let localStarred = StarredCoreDataAPI.loadStarredDebates()
        context.delete(localStarred)
    }

    // MARK: - Helpers

    // Handle the logic of loading data if it exists and creating+loading if it doesn't
    private static func loadStarredDebates() -> LocalStarred {
        // Explicit type for generic method
        let localStarredRecords: [LocalStarred]? = CoreDataService.fetchRecordsForEntity(CoreDataConstants.starredEntity,
                                                                                         in: StarredCoreDataAPI.context,
                                                                                         unique: true)
        // If it's a new user (no localStarredRecords) create a starred list
        let localStarred = localStarredRecords?.first ?? LocalStarred(context: StarredCoreDataAPI.context)

        return localStarred
    }

    // MARK: - Predicates

    private static let debatePrimaryKeyPredicate = { (debatePrimaryKey: PrimaryKey) -> NSPredicate in
        NSPredicate(format: "%K = %@",
                    CoreDataConstants.primaryKeyAttribute,
                    NSNumber(value: debatePrimaryKey))
    }

}
