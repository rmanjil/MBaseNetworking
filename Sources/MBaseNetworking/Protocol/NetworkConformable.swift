//
//  File.swift
//  
//
//  Created by manjil on 05/09/2023.
//

import Foundation
import Network

@available(macOS 10.15.0, *)
@available(iOS 13.0.0, *)

public protocol NetworkConformable {
    @available(iOS 13.0.0, *)
    static func initialize(with config: NetworkingConfiguration)
  
    func dataRequest<T>(router: NetworkingRouter ,type: T.Type) async throws -> T?
    func dataRequest<O>(router: NetworkingRouter ,type: O.Type) async throws -> Response<O>
    func multipartRequest<O>(router: NetworkingRouter, multipart: [File], type: O.Type) async throws -> Response<O>
}
