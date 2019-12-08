//
//  OptionalType.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 12/7/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation

public protocol OptionalType {
    associatedtype Wrapped
    var value: Wrapped? { get }
}

extension Optional: OptionalType {
    public var value: Wrapped? { return self }
}
