//
//  PointsNavigatorViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/31/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya
import RxCocoa
import RxSwift

class PointsNavigatorViewModel {

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
        guard pointImages[safe: index] != nil else { return nil }

        guard let singlePointImageViewController = pointImageViewControllers[safe: index] else {
            let newPointImageViewModel = SinglePointImageViewModel(pointImage: pointImages[index])
            let newPointImageViewController = SinglePointImageViewController(viewModel: newPointImageViewModel)
            pointImageViewControllers.append(newPointImageViewController)
            return newPointImageViewController
        }

        return singlePointImageViewController
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
        return UserDataManager.shared.markProgress(pointPrimaryKey: point.primaryKey,
                                                   debatePrimaryKey: debate.primaryKey,
                                                   totalPoints: debate.totalPoints)
    }

}
