//
//  Collection+SafeIndex.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 9/10/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation

extension Collection {
    subscript (safe index: Index) -> Element? {
        return (index >= startIndex && index < endIndex) ? self[index] : nil
    }
}
