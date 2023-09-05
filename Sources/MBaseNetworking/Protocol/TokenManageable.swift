//
//  File.swift
//  
//
//  Created by manjil on 05/09/2023.
//

import Foundation

@available(iOS 13.0.0, *)
@available(macOS 10.15.0, *)
public protocol TokenManageable {
   
    func refreshToken() async -> Bool
    func isTokenValid() -> Bool
    var tokenParam: [String: String] {get }
    
}
