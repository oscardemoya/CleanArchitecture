//
//  String+Utils.swift
//  CleanArchitecture
//
//  Created by Oscar De Moya on 2025/7/12.
//

import Foundation

extension String {
    /// Converts a type name to a variable name (e.g., "RemoteConfig" -> "remoteConfig")
    var asVariableName: String {
        guard let first else { return self }
        return first.lowercased() + dropFirst()
    }
    
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Checks if the string is a valid array type (e.g., "Array<Int>", "[String]", etc.)
    var isArrayType: Bool { self.contains(#/^\s*(\[\s*\w+\s*\]|Array<\s*\w+\s*>)\s*\??\s*$/#) }
    
    /// Extracts the element type from an array type string (e.g., "Array<Int>" -> "Int", "[String]" -> "String")
    var arrayElementType: String? {
        guard let match = self.firstMatch(of: #/(?:\[\s*|\bArray\s*<\s*)(\w+)(?:\s*\]|\s*>)\??/#) else { return nil }
        return String(match.1)
    }
}
