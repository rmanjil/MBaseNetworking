//
//  File.swift
//  
//
//  Created by manjil on 05/09/2023.
//

import Foundation

public struct Response<T: Decodable> {
    var data: T
    var statusCode: Int
}
