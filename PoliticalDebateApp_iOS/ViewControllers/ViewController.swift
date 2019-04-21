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
        temp?.makeRequest(with: .debate(primaryKey: 1) ).subscribe(
        onSuccess: { response in
            print(try? JSONDecoder().decode(Debate.self, from: response.data))
        }, onError: { error in
            print(error)
        }).disposed(by: tempD)
    }

}
