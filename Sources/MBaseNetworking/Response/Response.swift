//
//  File.swift
//  
//
//  Created by manjil on 05/09/2023.
//

import Foundation

public struct Response<T: Decodable> {
    public var data: T
    public var statusCode: Int
}
