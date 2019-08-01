//
//  DebugLog.swift
//  PoliticalDebateApp_iOS
//
//  Created by Samy on 6/20/19.
//  Copyright © 2019 PoliticalDebateApp. All rights reserved.
//

func debugLog(_ message: @autoclosure () -> Any, fileName: String = #file, methodName: String = #function, lineNumber: Int = #line) {
    #if DEBUG
    print("[File] \(fileName)\n[Method] \(methodName)\n[Line] \(lineNumber)\n\t\(message())")
    #endif
}
