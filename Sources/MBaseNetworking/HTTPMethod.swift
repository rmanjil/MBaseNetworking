//
//  File.swift
//  
//
//  Created by manjil on 05/09/2023.
//

import Foundation

public enum HTTPMethod {
    
    case get, post, put, delete, patch
    
    var identifier: String {
        switch self {
            case .get: return "GET"
            case .post: return "POST"
            case .put: return "PUT"
            case .delete: return "DELETE"
            case .patch: return "PATCH"
        }
    }
}
