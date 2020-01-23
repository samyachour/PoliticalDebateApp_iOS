//
//  Collection+SafeIndex.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 9/10/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Foundation

extension Collection {
    /// Optional indexing
    ///
    /// - Parameter safe index: the index that is not guaranteed to be within the bounds of the collection
    /// - Returns: Optional element, nil if index is outside the bounds
    ///
    ///    ```
    ///    let array = [1, 2, 3]
    ///    array[safe: 2] // Optional<Int>(.some(3))
    ///    array[safe: 3] // Optional<Int>(.none)
    ///    ```
    subscript (safe index: Index) -> Element? {
        return (index >= startIndex && index < endIndex) ? self[index] : nil
    }
}
