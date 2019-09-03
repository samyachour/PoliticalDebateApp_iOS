//
//  PointViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/31/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift

class PointViewModel {

    init(point: Point,
         debate: Debate) {
        self.point = point
        self.debate = debate
    }

    private let disposeBag = DisposeBag()

    // MARK: - Datasource

    let point: Point
    let debate: Debate

    private lazy var pointImages = point.images
    lazy var pointImagesCount = pointImages.count
    private var pointImageViewControllers = [SinglePointImageViewController]()

    func getImagePage(at index: Int) -> SinglePointImageViewController? {
        guard index >= 0 && index < pointImages.count else {
            return nil
        }
        guard index < pointImageViewControllers.count else {
            let newPointImageViewModel = SinglePointImageViewModel(pointImage: pointImages[index])
            let newPointImageViewController = SinglePointImageViewController(viewModel: newPointImageViewModel)
            pointImageViewControllers.append(newPointImageViewController)
            return newPointImageViewController
        }

        return pointImageViewControllers[index]
    }

    func getIndexOf(_ viewController: UIViewController) -> Int? {
        guard let pointImageViewController = viewController as? SinglePointImageViewController else {
            return nil
        }

        return pointImageViewControllers.firstIndex(of: pointImageViewController)
    }

    // MARK: - API calls

    private let progressNetworkService = NetworkService<ProgressAPI>()

    func markAsSeen() -> Single<Response?>? {
        guard !UserDataManager.shared.getProgress(for: debate.primaryKey)
            .seenPoints.contains(point.primaryKey) else {
                return nil
        }

        return UserDataManager.shared.markProgress(pointPrimaryKey: point.primaryKey,
                                                   debatePrimaryKey: debate.primaryKey,
                                                   totalPoints: debate.totalPoints)
    }

}
