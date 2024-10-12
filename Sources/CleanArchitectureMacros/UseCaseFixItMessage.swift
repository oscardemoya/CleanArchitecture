//
//  UseCaseFixItMessage.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 10/12/24.
//

import SwiftDiagnostics

enum UseCaseFixItMessage: String, FixItMessage {
    case replaceClassWithStruct
    
    var message: String {
        switch self {
        case .replaceClassWithStruct:
            return "Replace 'class' with 'struct'"
        }
    }
    
    var fixItID: MessageID {
        return MessageID(domain: "UseCaseMacro", id: rawValue)
    }
}
