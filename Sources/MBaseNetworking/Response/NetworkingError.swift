//
//  File.swift
//
//
//  Created by manjil on 05/09/2023.
//

import Foundation

public extension Error {
     var errorCode: Int {
        return (self as NSError).code
    }
}

enum NetworkErrorType {
    case networkingNotInitialized
    case invalidBaseURL
    case jsonEncodingFailed(Error)
    case noConnectivity
    case invalidStatusCode(Int)
}

public struct NetworkingError: LocalizedError {
    
    private let reason: String
    public let code: Int
    
    public init(_ reason: String, code: Int = 0) {
        self.reason = reason
        self.code = code
    }
    
    init(_ urlError: URLError) {
        switch urlError.code {
        case .networkConnectionLost, .dataNotAllowed, .notConnectedToInternet:
            self.reason = "Network connection not available"
        default:
            self.reason = urlError.localizedDescription
        }
        self.code = urlError.code.rawValue
    }
    
    init(_ error: Error) {
        self.reason = error.localizedDescription
        self.code = error.errorCode
    }
    
    init(_ type: NetworkErrorType) {
        
        switch type {
        case .networkingNotInitialized:
            self.code = 0
            self.reason = "The Networking class is not initialized with required configuration. Please make sure to initialize the Networking once when the app starts."
        case .invalidBaseURL:
            self.code = 0
            self.reason = "The provided base url is invalid or not properly constructed as url"
        case .jsonEncodingFailed(let error):
            self.code = 0
            self.reason = "Failed to encode parameters to JSON \(error.localizedDescription)"
        case .noConnectivity:
            self.code = 0
            self.reason = "A data connection cannot be made at the moment. Please check your network connection and try again."
        case .invalidStatusCode( let code):
            self.reason = ""
            self.code = code
        }
    }
    
    public var errorDescription: String? {
        return reason
    }
}
