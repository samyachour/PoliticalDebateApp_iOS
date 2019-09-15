//
//  ProgressCoreDataAPI
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/21/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import CoreData

final class ProgressCoreDataAPI {

    // MARK: - CRUD operations

    static func saveProgress(pointPrimaryKey: PrimaryKey, debatePrimaryKey: PrimaryKey, totalPoints: Int) {
        defer { CoreDataService.saveContext() }

        let (localProgress, _) = ProgressCoreDataAPI.loadProgressAndAssociatedDebate(debatePrimaryKey)

        let localPointRecords: [LocalPoint]? = CoreDataService
            .fetchRecordsForEntity(CoreDataConstants.pointEntity,
                                   with: ProgressCoreDataAPI.pointLabelPredicate(pointPrimaryKey, debatePrimaryKey),
                                   unique: true)

        // Never saved this point before
        if localPointRecords?.first == nil {
            let localPoint: LocalPoint = CoreDataService.createRecord()
            localPoint.primaryKey = Int32(pointPrimaryKey)
            localPoint.progress = localProgress // to one

            localProgress.addToSeenPoints(localPoint) // to many
            if let completedCount = localProgress.seenPoints?.allObjects.count {
                let completedPercentage = (Float(completedCount) / Float(totalPoints)) * 100
                localProgress.completedPercentage = Int16(completedPercentage)
            }
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

        localProgressRecords.forEach { (localProgress) in
            CoreDataService.deleteRecord(localProgress)
        }
    }

    // MARK: - Helpers

    // Handle the logic of loading data if it exists and creating+loading if it doesn't
    private static func loadProgressAndAssociatedDebate(_ debatePrimaryKey: PrimaryKey) -> (LocalProgress, LocalDebate) {
        // Explicit type for generic method
        let localDebateRecords: [LocalDebate]? = CoreDataService
            .fetchRecordsForEntity(CoreDataConstants.debateEntity,
                                   with: ProgressCoreDataAPI.debatePrimaryKeyPredicate(debatePrimaryKey),
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

    private static let debatePrimaryKeyPredicate = { (debatePrimaryKey: PrimaryKey) -> NSPredicate in
        NSPredicate(format: "%K = %@",
                    CoreDataConstants.primaryKeyAttribute,
                    NSNumber(value: Int32(debatePrimaryKey)))
    }
    private static let pointLabelPredicate = { (pointPrimaryKey: PrimaryKey, debatePrimaryKey: PrimaryKey) -> NSPredicate in
        NSPredicate(format: "%K = %@ AND %K.%K.%K = %@",
                    CoreDataConstants.primaryKeyAttribute,
                    NSNumber(value: Int32(pointPrimaryKey)),
                    CoreDataConstants.progressRelationshipAttribute,
                    CoreDataConstants.debateRelationshipAttribute,
                    CoreDataConstants.primaryKeyAttribute,
                    NSNumber(value: Int32(debatePrimaryKey)))
    }
}
