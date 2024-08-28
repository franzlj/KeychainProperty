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
    
    private let valueSubject: any Subject<T?, Never>
    
    /// KeychainProperty initializer.
    ///
    /// The accessibility of this item is currently always set to `.whenPasscodeSetThisDeviceOnly`.
    /// When biometric protection is enabled, it is currently always set to `.biometryCurrentSet`.
    /// - Parameters:
    ///   - serviceIdentifier: Service Identifier for the keychain
    ///   - valueKey: Key for the value within the keychain
    ///   - requiresBiometry: whether this value should be protected by biometric authentication.
    ///   - cacheValue: Whether biometric protected values should be cached after first read.
    ///   - logger: Optional `Logger` to log to
    public init(
        serviceIdentifier: String = Bundle.main.bundleIdentifier!,
        valueKey: String,
        requiresBiometry: Bool = false,
        cacheValue: Bool = false,
        logger: Logger? = nil
    ) {
        self.serviceIdentifier = serviceIdentifier
        self.valueKey = valueKey
        self.requiresBiometry = requiresBiometry
        self.logger = logger
        self.valueSubject = if cacheValue {
            CurrentValueSubject<T?, Never>(nil)
        } else {
            PassthroughSubject()
        }
        
        if requiresBiometry {
            self.keychain = Keychain(service: serviceIdentifier)
                .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .biometryCurrentSet)
        } else {
            self.keychain = Keychain(service: serviceIdentifier)
                .accessibility(.whenPasscodeSetThisDeviceOnly)
        }
        
        if cacheValue && !requiresBiometry {
            // Sending value on init should not trigger a direct FaceID,
            // and only makes sense, when we are not caching.
            valueSubject.send(wrappedValue)
        }
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

private extension Subject {
    
    /// Provide `value`property to all Subjects.
    /// Will only provide an actual value if the underlying subject is a `CurrentValueSubject`.
    var value: Output? {
        (self as? CurrentValueSubject<Output, Failure>)?.value
    }
}
