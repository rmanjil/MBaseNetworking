//
//  File.swift
//  
//
//  Created by manjil on 05/09/2023.
//

import Foundation
import Network
import SystemConfiguration


public enum ConnectivityStatus {
    case connected, disconnected, unknown
}

@available(iOS 12.0, *)
@available(macOS 10.14, *)
class Connectivity {
    
    static let `default` = Connectivity()
    
    var stateTrigger: ((ConnectivityStatus)-> Void)?
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "Monitor")
    var connected: Bool = false
    public var status: ConnectivityStatus { getCurrentConnectivityStatus() }
    
    private init() {
        checkConnection()
    }
    
    private func getCurrentConnectivityStatus() -> ConnectivityStatus {
        if connected {
            return .connected
        } else {
            return .disconnected
        }
    }
    
    func connectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
    
    private func checkConnection() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.connected = true
            } else {
                self.connected = false
            }
        }
        monitor.start(queue: queue)
    }
}
