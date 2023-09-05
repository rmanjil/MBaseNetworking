//
//  File.swift
//  
//
//  Created by manjil on 05/09/2023.
//

import Foundation

struct ResponseParser {
    let result: (data: Data, response: URLResponse)
    
    // parse the data from response
    func parse() throws {
        guard let urlResponse = result.response as? HTTPURLResponse else { assertionFailure(); return }
        guard !(200...299 ~= urlResponse.statusCode) else { return }
        throw NetworkingError(.invalidStatusCode(urlResponse.statusCode))
    }
}
