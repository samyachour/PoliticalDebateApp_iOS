//
//  ProgressCoreDataAPI
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/21/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import CoreData

final class ProgressCoreDataAPI {

    // MARK: - Core data

    // So all our tasks run on the same private background queue when updating/retreiving records
    private static let context = CoreDataService.persistentContainer.newBackgroundContext()
    private static let saveContext = {
        do {
            try ProgressCoreDataAPI.context.save()
        } catch {
            CoreDataService.showCoreDataSaveAlert()
        }
    }

    // MARK: - CRUD operations

    static func saveProgress(pointPrimaryKey: PrimaryKey, debatePrimaryKey: PrimaryKey, totalPoints: Int) {
        defer { saveContext() }

        let (localProgress, _) = ProgressCoreDataAPI.loadProgressAndAssociatedDebate(debatePrimaryKey)

        let localPointRecords: [LocalPoint]? = CoreDataService
            .fetchRecordsForEntity(CoreDataConstants.pointEntity,
                                   in: ProgressCoreDataAPI.context,
                                   with: ProgressCoreDataAPI.pointLabelPredicate(pointPrimaryKey, debatePrimaryKey),
                                   unique: true)

        // Never saved this point before
        if localPointRecords?.first == nil {
            let localPoint = LocalPoint(context: ProgressCoreDataAPI.context)
            localPoint.primaryKey = Int32(pointPrimaryKey)
            localPoint.progress = localProgress // to one

            localProgress.addToSeenPoints(localPoint) // to many
            if let completionCount = localProgress.seenPoints?.allObjects.count {
                let completionPercentage = Float(completionCount) / Float(totalPoints)
                localProgress.completedPercentage = Int16(completionPercentage * 100)
            }
        }
    }

    static func loadAllProgress() -> [Progress?]? {
        defer { saveContext() }

        // Explicit type for generic method
        guard let localProgressRecords: [LocalProgress] = CoreDataService
            .fetchRecordsForEntity(CoreDataConstants.progressEntity, in: ProgressCoreDataAPI.context) else {
                return nil
        }

        return localProgressRecords.map({ localProgress -> Progress? in
            Progress(from: localProgress)
        })
    }

    static func loadProgress(_ debatePrimaryKey: PrimaryKey) -> Progress? {
        defer { saveContext() }

        let (localProgress, _) = ProgressCoreDataAPI.loadProgressAndAssociatedDebate(debatePrimaryKey)

        return Progress(from: localProgress, withSeenPoints: true)
    }

    static func clearAllProgress() {
        defer { saveContext() }

        // Explicit type for generic method
        guard let localProgressRecords: [LocalProgress] = CoreDataService
            .fetchRecordsForEntity(CoreDataConstants.progressEntity, in: ProgressCoreDataAPI.context) else {
                return
        }

        localProgressRecords.forEach { (localProgress) in
            context.delete(localProgress)
        }
    }

    // MARK: - Helpers

    // Handle the logic of loading data if it exists and creating+loading if it doesn't
    private static func loadProgressAndAssociatedDebate(_ debatePrimaryKey: PrimaryKey) -> (LocalProgress, LocalDebate) {
        // Explicit type for generic method
        let localDebateRecords: [LocalDebate]? = CoreDataService
            .fetchRecordsForEntity(CoreDataConstants.debateEntity,
                                   in: ProgressCoreDataAPI.context,
                                   with: ProgressCoreDataAPI.debatePrimaryKeyPredicate(debatePrimaryKey),
                                   unique: true)
        let localDebate = localDebateRecords?.first ?? LocalDebate(context: ProgressCoreDataAPI.context)
        localDebate.primaryKey = Int32(debatePrimaryKey)

        let localProgress = localDebate.progress ?? LocalProgress(context: ProgressCoreDataAPI.context)

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
                    CoreDataConstants.pointLabelAttribute,
                    NSNumber(value: Int32(pointPrimaryKey)),
                    CoreDataConstants.progressRelationshipAttribute,
                    CoreDataConstants.debateRelationshipAttribute,
                    CoreDataConstants.primaryKeyAttribute,
                    NSNumber(value: Int32( debatePrimaryKey)))
    }
}
