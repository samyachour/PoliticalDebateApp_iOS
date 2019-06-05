//
//  DebatesListViewModel.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/4/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import RxSwift

public class DebateListViewModel {

    // MARK: Observables

    // MARK: API calls

    // TODO: Combine latest of search input and picker choice and make search query
}

public enum SortByOptions: Int, CaseIterable {
    case sortBy
    case lastUpdated
    case starred
    case progress
    case noProgress

    var stringValue: String {
        switch self {
        case .sortBy: return "Sort by"
        case .lastUpdated: return "Last updated"
        case .starred: return "Starred"
        case .progress: return "Progress"
        case .noProgress: return "No progress"
        }
    }

    var selectionColor: UIColor {
        switch self {
        case .sortBy: return DebatesListViewController.buttonColor
        default: return DebatesListViewController.selectedColor
        }
    }
}
