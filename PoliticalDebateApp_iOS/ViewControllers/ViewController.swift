//
//  ViewController.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 4/19/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import RxSwift
import UIKit

class ViewController: UIViewController {

    var temp: NetworkService<DebateAPI>?
    let tempD = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        temp = NetworkService<DebateAPI>()
        temp?.makeRequest(with: .debate(primaryKey: 2) )
            .map(Debate.self)
            .subscribe(onSuccess: { debate in
                print(debate)
            }).disposed(by: tempD)
    }

}
