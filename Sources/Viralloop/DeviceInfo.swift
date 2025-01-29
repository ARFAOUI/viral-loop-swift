//
//  DeviceInfo.swift
//  viralloop
//
//  Created by Bechir Arfaoui on 15.01.25.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import Network

internal struct DeviceInfo {
    static func getDeviceInfo() -> (deviceType: String, brand: String, model: String, os: String, osVersion: String) {
        #if os(iOS)
            return (
                deviceType: "ios",
                brand: "Apple",
                model: UIDevice.current.model,
                os: UIDevice.current.systemName,
                osVersion: UIDevice.current.systemVersion
            )
        #elseif os(macOS)
            return (
                deviceType: "macos",
                brand: "Apple",
                model: "Mac",
                os: "macOS",
                osVersion: ProcessInfo.processInfo.operatingSystemVersionString
            )
        #else
            return (
                deviceType: "unknown",
                brand: "unknown",
                model: "unknown",
                os: "unknown",
                osVersion: "unknown"
            )
        #endif
    }
    
    static func getAppInfo() -> (version: String, buildNumber: Int) {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return (version: version, buildNumber: Int(build) ?? 1)
    }
    
    static func generateUserId() -> String {
        #if os(iOS)
            if let identifierForVendor = UIDevice.current.identifierForVendor {
                return identifierForVendor.uuidString
            }
        #endif
        return UUID().uuidString
    }
    
    static func getCurrentConnectivity() -> String {
        let monitor = NWPathMonitor()
        var connectivity = "unknown"
        
        if monitor.currentPath.usesInterfaceType(.wifi) {
            connectivity = "Wifi"
        } else if monitor.currentPath.usesInterfaceType(.cellular) {
            connectivity = "Cellular"
        }
        
        return connectivity
    }
}
