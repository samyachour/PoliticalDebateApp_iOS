//
//  MoyaTargetType+ValidSuccessCodes.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 9/2/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya

protocol CustomTargetType: TargetType {
    var validSuccessCode: Int { get }
}
