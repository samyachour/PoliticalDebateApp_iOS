//
//  DebateCellViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 8/6/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import UIKit

struct DebateCellViewModel {
    let debate: Debate
    let completedPercentage: Float
    let starTintColor: UIColor

    init(debate: Debate, completedPercentage: Float, isStarred: Bool) {
        self.debate = debate
        self.completedPercentage = completedPercentage
        self.starTintColor = isStarred ? .blue : .gray // TODO: Fix
    }
}
