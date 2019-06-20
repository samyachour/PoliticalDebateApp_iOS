//
//  LoginViewController.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/4/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

public class LoginViewController: UIViewController {

    public required init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil) // we don't use nibs
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: VC Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()

//        installViewConstraints()
//        installViewBinds()
    }

    // MARK: Dependencies
    private let sessionManager = SessionManager.shared

    // MARK: Observers & Observables

    private let viewModel: LoginViewModel

    // MARK: Action handlers

    // MARK: UI Properties

}
