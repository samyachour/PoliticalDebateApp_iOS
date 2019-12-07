//
//  ProgressCoreDataAPI
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/21/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import CoreData

struct ProgressCoreDataAPI {

    private init() {}

    // MARK: - CRUD operations

    static func saveProgress(pointPrimaryKey: PrimaryKey, debatePrimaryKey: PrimaryKey) {
        defer { CoreDataService.saveContext() }

        let (localProgress, _) = Self.loadProgressAndAssociatedDebate(debatePrimaryKey)

        let localPointRecords: [LocalPoint]? = CoreDataService
            .fetchRecordsForEntity(CoreDataConstants.pointEntity,
                                   with: Self.generatePointLabelPredicate(pointPrimaryKey: pointPrimaryKey, debatePrimaryKey: debatePrimaryKey),
                                   unique: true)

        // Never saved this point before
        if localPointRecords?.first == nil {
            let localPoint: LocalPoint = CoreDataService.createRecord()
            localPoint.primaryKey = Int32(pointPrimaryKey)
            localPoint.progress = localProgress // to one

            localProgress.addToSeenPoints(localPoint) // to many
        }
    }

    static func loadAllProgress() -> [Progress?]? {
        defer { CoreDataService.saveContext() }

        // Explicit type for generic method
        guard let localProgressRecords: [LocalProgress] = CoreDataService
            .fetchRecordsForEntity(CoreDataConstants.progressEntity) else {
                return nil
        }

        return localProgressRecords.map({ localProgress -> Progress? in
            Progress(from: localProgress)
        })
    }

    static func clearAllProgress() {
        defer { CoreDataService.saveContext() }

        // Explicit type for generic method
        guard let localProgressRecords: [LocalProgress] = CoreDataService
            .fetchRecordsForEntity(CoreDataConstants.progressEntity) else {
                return
        }

        localProgressRecords.forEach { localProgress in
            CoreDataService.deleteRecord(localProgress)
        }
    }

    static func removePoint(_ pointPrimaryKey: PrimaryKey) {
        defer { CoreDataService.saveContext() }

        // Explicit type for generic method
        guard let localPointRecords: [LocalPoint] = CoreDataService
            .fetchRecordsForEntity(CoreDataConstants.pointEntity, with: generatePrimaryKeyPredicate(pointPrimaryKey), unique: true),
            let localPoint = localPointRecords.first else {
                return
        }

        CoreDataService.deleteRecord(localPoint)
    }

    // MARK: - Helpers

    /// Handle the logic of loading data if it exists and creating+loading if it doesn't
    private static func loadProgressAndAssociatedDebate(_ debatePrimaryKey: PrimaryKey) -> (LocalProgress, LocalDebate) {
        // Explicit type for generic method
        let localDebateRecords: [LocalDebate]? = CoreDataService
            .fetchRecordsForEntity(CoreDataConstants.debateEntity,
                                   with: Self.generatePrimaryKeyPredicate(debatePrimaryKey),
                                   unique: true)
        let localDebate: LocalDebate = localDebateRecords?.first ?? CoreDataService.createRecord()
        localDebate.primaryKey = Int32(debatePrimaryKey)

        let localProgress: LocalProgress = localDebate.progress ?? CoreDataService.createRecord()

        // One to one relationship
        localProgress.debate = localDebate
        localDebate.progress = localProgress

        return (localProgress, localDebate)
    }

    // MARK: - Predicates

    private static func generatePrimaryKeyPredicate(_ primaryKey: PrimaryKey) -> NSPredicate {
        return NSPredicate(format: "%K = %@",
                           CoreDataConstants.primaryKeyAttribute,
                           NSNumber(value: Int32(primaryKey)))
    }

    private static func generatePointLabelPredicate(pointPrimaryKey: PrimaryKey, debatePrimaryKey: PrimaryKey) -> NSPredicate {
        return NSPredicate(format: "%K = %@ AND %K.%K.%K = %@",
                           CoreDataConstants.primaryKeyAttribute,
                           NSNumber(value: Int32(pointPrimaryKey)),
                           CoreDataConstants.progressRelationshipAttribute,
                           CoreDataConstants.debateRelationshipAttribute,
                           CoreDataConstants.primaryKeyAttribute,
                           NSNumber(value: Int32(debatePrimaryKey)))
    }
}
