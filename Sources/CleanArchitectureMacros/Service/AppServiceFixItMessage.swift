//
//  AppServiceFixItMessage.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/13/24.
//

import SwiftDiagnostics

enum AppServiceFixItMessage: String, FixItMessage {
    case replaceStructWithClass
    
    var message: String {
        switch self {
        case .replaceStructWithClass:
            return "Replace 'struct' with 'class'"
        }
    }
    
    var fixItID: MessageID {
        return MessageID(domain: "AppServiceMacro", id: rawValue)
    }
}
