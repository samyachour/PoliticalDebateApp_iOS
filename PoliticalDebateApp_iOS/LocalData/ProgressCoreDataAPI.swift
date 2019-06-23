//
//  ProgressCoreDataAPI
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/21/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import CoreData

public final class ProgressCoreDataAPI {

    // MARK: Core data

    // So all our tasks run on the same private background queue when updating/retreiving records
    private static let context = CoreDataService.persistentContainer.newBackgroundContext()
    private static let saveContext = {
        do {
            try ProgressCoreDataAPI.context.save()
        } catch {
            CoreDataService.showCoreDataSaveAlert()
        }
    }

    // MARK: CRUD operations

    public static func saveProgress(point: String, debatePrimaryKey: PrimaryKey, totalPoints: Int) {
        defer { saveContext() }

        let (localProgress, _) = ProgressCoreDataAPI.loadProgressAndAssociatedDebate(debatePrimaryKey)

        let localPointRecords: [LocalPoint]? = CoreDataService
            .fetchRecordsForEntity(CoreDataConstants.pointEntity,
                                   in: ProgressCoreDataAPI.context,
                                   with: ProgressCoreDataAPI.pointLabelPredicate(point, debatePrimaryKey),
                                   unique: true)

        // Never saved this point before
        if localPointRecords?.first == nil {
            let localPoint = LocalPoint(context: ProgressCoreDataAPI.context)
            localPoint.label = point
            localPoint.progress = localProgress // to one

            localProgress.addToSeenPoints(localPoint) // to many
            if let completionCount = localProgress.seenPoints?.allObjects.count {
                let completionPercentage = Float(completionCount) / Float(totalPoints)
                localProgress.completedPercentage = Int16(completionPercentage * 100)
            }
        }
    }

    public static func loadAllProgress() -> [Progress?]? {
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

    public static func loadProgress(_ debatePrimaryKey: PrimaryKey) -> Progress? {
        defer { saveContext() }

        let (localProgress, _) = ProgressCoreDataAPI.loadProgressAndAssociatedDebate(debatePrimaryKey)

        return Progress(from: localProgress, withSeenPoints: true)
    }

    // MARK: Helpers

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

    // MARK: Predicates

    private static let debatePrimaryKeyPredicate = { (debatePrimaryKey: PrimaryKey) -> NSPredicate in
        NSPredicate(format: "%K = %@",
                    CoreDataConstants.primaryKeyAttribute,
                    NSNumber(value: Int32(debatePrimaryKey)))
    }
    private static let pointLabelPredicate = { (pointLabel: String, debatePrimaryKey: PrimaryKey) -> NSPredicate in
        NSPredicate(format: "%K = %@ AND %K.%K.%K = %@",
                    CoreDataConstants.pointLabelAttribute,
                    pointLabel,
                    CoreDataConstants.progressRelationshipAttribute,
                    CoreDataConstants.debateRelationshipAttribute,
                    CoreDataConstants.primaryKeyAttribute,
                    NSNumber(value: Int32( debatePrimaryKey)))
    }
}
