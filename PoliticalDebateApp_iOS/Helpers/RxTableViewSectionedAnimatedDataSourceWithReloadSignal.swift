//
//  RxTableViewSectionedAnimatedDataSourceWithReloadSignal.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 10/27/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import RxCocoa
import RxDataSources
import RxSwift

// swiftlint:disable:next type_name
final class RxTableViewSectionedAnimatedDataSourceWithReloadSignal<S: AnimatableSectionModelType>: RxTableViewSectionedAnimatedDataSource<S> {
    private let relay = PublishRelay<Void>()
    lazy var dataReloaded = relay.asSignal()

    override func tableView(_ tableView: UITableView, observedEvent: Event<[S]>) {
        super.tableView(tableView, observedEvent: observedEvent)
        relay.accept(())
    }
}
