//
//  Observable+FilterNil.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 12/7/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation
import RxSwift

extension ObservableType where Element: OptionalType {
    func filterNil() -> Observable<Element.Wrapped> {
        return self.flatMap { element -> Observable<Element.Wrapped> in
            guard let value = element.value else {
                return .empty()
            }
            return .just(value)
        }
    }
}
