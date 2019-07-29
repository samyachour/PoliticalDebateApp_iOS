//
//  AccountViewController.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/4/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

class AccountViewController: UIViewController {

    required init(viewModel: AccountViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil) // we don't use nibs
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        //        installViewConstraints()
        //        installViewBinds() // TODO: subscribe to isActive session and dismiss self if not
    }

    // MARK: - Dependencies
    private let sessionManager = SessionManager.shared

    // MARK: - Observers & Observables

    private let viewModel: AccountViewModel

}
