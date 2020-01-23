//
//  UITableView+LayoutHeaderVIew.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 1/1/20.
//  Copyright © 2020 PoliticalDebateApp. All rights reserved.
//

import UIKit

extension UITableView {

    /// Table header views do not support automatic resizing based on intrinsic size
    /// so this method will grab the size and set the frame manually
    /// - Important: Should be called from `didLayoutSubviews`
    func layoutHeaderView() {
        guard let headerView = tableHeaderView else { return }

        let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        var headerFrame = headerView.frame

        // Comparison is necessary to avoid infinite loop
        if height != headerView.frame.size.height {
            headerFrame.size.height = height
            headerView.frame = headerFrame
            tableHeaderView = headerView
        }
    }
}
