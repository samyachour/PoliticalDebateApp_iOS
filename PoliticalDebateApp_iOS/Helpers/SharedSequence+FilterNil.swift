//
//  SharedSequence+FilterNil.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 12/7/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

extension SharedSequence where Element: OptionalType {
    /// Safely unwrap and compact map the values of a sequence
    func filterNil() -> SharedSequence<SharingStrategy, Element.Wrapped> {
        return self.flatMap { element -> SharedSequence<SharingStrategy, Element.Wrapped> in
            guard let value = element.value else {
                return .empty()
            }
            return .just(value)
        }
    }
}
