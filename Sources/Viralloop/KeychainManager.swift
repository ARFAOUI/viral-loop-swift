//
//  KeychainManager.swift
//  Viralloop
//
//  Created by Bechir Arfaoui on 22.01.25.
//
import Foundation
import Security

enum KeychainError: Error {
    case duplicateEntry
    case unknown(OSStatus)
    case itemNotFound
    case invalidItemFormat
    case unexpectedData
}

class KeychainManager {
    static let shared = KeychainManager()
    private init() {}
    
    func save(_ data: Data, service: String, account: String) throws {
        // Updated query with more permissive options
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecValueData as String: data as AnyObject,
            // Changed from kSecAttrAccessibleAfterFirstUnlock
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked as AnyObject,
            // Add synchronization options
            kSecAttrSynchronizable as String: kCFBooleanFalse
        ]
        
        // First try to delete any existing item
        let deleteQuery: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account as AnyObject
        ]
        
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Now add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    func retrieve(service: String, account: String) throws -> Data {
        let query: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecReturnData as String: kCFBooleanTrue,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: kCFBooleanFalse
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unknown(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidItemFormat
        }
        
        return data
    }
}
