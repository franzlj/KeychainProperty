# KeychainProperty

Swift property wrapper for basic [`KeychainAccess`](https://github.com/kishikawakatsumi/KeychainAccess) usage.

## Introduction

This micro-framework provides a very limited and opiniated use of the KeychainAccess framework (see Package.swift dependencies):
* It provides access to a specified keychain key via a property wrapper for any `Codable` value - which allows to easily safe bigger structures into the Keychain
* It allows to switch on biometric access to that property, which will require authentication when the property is read
* It will cache the last retrieved value during runtime of the app, to not trigger any biometric authentication when this property needs to be read a second time during runtime

## Usage

```swift
    // Simple value
    @KeychainProperty(valueKey: "1FATokenData") 
    private var tokens1FA: TokenData?
    
    /// Biometric authentication for a value
    @KeychainProperty(
        valueKey: "2FATokenData", 
        requiresBiometry: true
    )
    private var tokens2FA: TokenData?
```

## Future, unscheduled changes

As mentioned, this thing does only one particular thing, and it might be a good idea to extend upon it:
* Introduce a timeout at which the cache will reset
* Migration support
* ...

## Thanks

Thanks to the Framework [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) this micro-framework is based on.

## License

MIT