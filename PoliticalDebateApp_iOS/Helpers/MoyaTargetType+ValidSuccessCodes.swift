//
//  MoyaTargetType+ValidSuccessCodes.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 9/2/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

import Moya

/// Protocol to enforce the success condition so it only occurs when the expected success code comes back
protocol CustomTargetType: TargetType {
    var validSuccessCode: Int { get }
}
