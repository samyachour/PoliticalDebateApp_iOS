//
//  StarredCoreDataAPI.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/22/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import CoreData

struct StarredCoreDataAPI {

    private init() {}

    // MARK: - CRUD operations

    static func starOrUnstarDebate(_ debatePrimaryKey: PrimaryKey, unstar: Bool = false) {
        defer { CoreDataService.saveContext() }

        let localStarred = Self.loadStarredDebates()

        // Explicit type for generic method
        let localDebateRecords: [LocalDebate]? = CoreDataService
            .fetchRecordsForEntity(CoreDataConstants.debateEntity,
                                   with: Self.generatePrimaryKeyPredicate(debatePrimaryKey),
                                   unique: true)
        let localDebate: LocalDebate = localDebateRecords?.first ?? CoreDataService.createRecord()
        localDebate.primaryKey = Int32(debatePrimaryKey)

        if unstar {
            localDebate.starred = nil
            localStarred.removeFromStarredList(localDebate)
        } else {
            localDebate.starred = localStarred
            localStarred.addToStarredList(localDebate)
        }
    }

    static func loadAllStarred() -> Starred? {
        defer { CoreDataService.saveContext() }

        let localStarred = Self.loadStarredDebates()

        return Starred(from: localStarred)
    }

    static func clearAllStarred() {
        defer { CoreDataService.saveContext() }

        let localStarred = Self.loadStarredDebates()
        CoreDataService.deleteRecord(localStarred)
    }

    // MARK: - Helpers

    /// Handle the logic of loading data if it exists and creating+loading if it doesn't
    private static func loadStarredDebates() -> LocalStarred {
        // Explicit type for generic method
        let localStarredRecords: [LocalStarred]? = CoreDataService.fetchRecordsForEntity(CoreDataConstants.starredEntity,
                                                                                         unique: true)
        // If it's a new user (no localStarredRecords) create a starred list
        let localStarred: LocalStarred = localStarredRecords?.first ?? CoreDataService.createRecord()

        return localStarred
    }

    // MARK: - Predicates

    private static func generatePrimaryKeyPredicate(_ primaryKey: PrimaryKey) -> NSPredicate {
        return NSPredicate(format: "%K = %@",
                           CoreDataConstants.primaryKeyAttribute,
                           NSNumber(value: primaryKey))
    }

}
