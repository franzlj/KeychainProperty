//
//  KeychainProperty.swift
//  
//
//  Created by Franz on 02.01.24.
//

import Foundation
import OSLog
import Combine
import KeychainAccess

@propertyWrapper
public struct KeychainProperty<T: Codable> {
    private let serviceIdentifier: String
    private let valueKey: String
    private let requiresBiometry: Bool
    
    private let keychain: Keychain
    
    private let logger: Logger?
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private let valueSubject = CurrentValueSubject<T?, Never>(nil)
    
    init(
        serviceIdentifier: String = Bundle.main.bundleIdentifier!,
        valueKey: String,
        requiresBiometry: Bool = false,
        logger: Logger? = nil
    ) {
        self.serviceIdentifier = serviceIdentifier
        self.valueKey = valueKey
        self.requiresBiometry = requiresBiometry
        self.logger = logger
        
        if requiresBiometry {
            self.keychain = Keychain(service: serviceIdentifier)
                .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .biometryCurrentSet)
        } else {
            self.keychain = Keychain(service: serviceIdentifier)
                .accessibility(.whenPasscodeSetThisDeviceOnly)
        }
        
        valueSubject.send(wrappedValue)
    }
    
    public var wrappedValue: T? {
        get {
            // Use subject memory cached value if possible for biometry items
            if requiresBiometry, let value = valueSubject.value {
                logger?.debug("Returning \(valueKey) subject cached value...")
                return value
            }
            guard let data = keychain[data: valueKey] else {
                return nil
            }
            return try? decoder.decode(T.self, from: data)
        }
        set {
            #if DEBUG
            let valueKey = self.valueKey
            logger?.debug("Keychain: setting new value for key \"\(valueKey)\"")
            #endif
            if let newValue, let data = try? encoder.encode(newValue) {
                keychain[data: valueKey] = data
            } else {
                keychain[valueKey] = nil
            }
            
            valueSubject.send(newValue)
        }
    }
    
    public var projectedValue: AnyPublisher<T?, Never> {
        valueSubject.eraseToAnyPublisher()
    }
}
