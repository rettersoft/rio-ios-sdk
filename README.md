
# Rio - retter.io

[![CI Status](https://img.shields.io/travis/baranbaygan/Rio.svg?style=flat)](https://travis-ci.org/baranbaygan/Rio)
[![Version](https://img.shields.io/cocoapods/v/Rio.svg?style=flat)](https://cocoapods.org/pods/Rio)
[![License](https://img.shields.io/cocoapods/l/Rio.svg?style=flat)](https://cocoapods.org/pods/Rio)
[![Platform](https://img.shields.io/cocoapods/p/Rio.svg?style=flat)](https://cocoapods.org/pods/Rio)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## About Rio - retter.io

Rio can be used by developers to build serverless object oriented systems. You should create an retter.io account and an Rio project to start. 

https://c.retter.io

## Requirements

You need to have a Rio projectId.

## Installation

### Cocoapods

Rio is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Rio'
```

### Swift Package Manager

Add the package by its repository URL and depend on a release tag, not on `main`:

```swift
.package(url: "https://github.com/rettersoft/rio-ios-sdk", from: "0.1.0")
```

Rio ships its SSL pinning certificates as package resources since 0.1.0; earlier
versions silently ran without pinning when installed through Swift Package Manager.

## Initialize SDK

Initialize the SDK with your project id created in RBS console.

```swift
let rio = Rio.init(config: RioConfig(projectId: "{PROJECT_ID}"))
```

## Keychain Accessibility

Rio stores the session token (access & refresh token) in the iOS Keychain. You can control the Keychain accessibility level of this record via `RioConfig`:

```swift
let rio = Rio.init(config: RioConfig(
    projectId: "{PROJECT_ID}",
    keychainAccessibility: .whenUnlockedThisDeviceOnly
))
```

| Option | Readable when | Included in backups / migrates to a new device |
| --- | --- | --- |
| `.whenUnlocked` *(default behavior when not set)* | Device is unlocked | Yes |
| `.whenUnlockedThisDeviceOnly` | Device is unlocked | No |
| `.afterFirstUnlock` | Any time after first unlock since reboot (incl. locked) | Yes |
| `.afterFirstUnlockThisDeviceOnly` | Any time after first unlock since reboot (incl. locked) | No |
| `.whenPasscodeSetThisDeviceOnly` | Device is unlocked & has a passcode | No (deleted if passcode is removed) |

Notes:

- If you don't set `keychainAccessibility`, the SDK keeps its existing behavior (`.whenUnlocked`).
- `.whenUnlockedThisDeviceOnly` is recommended for most apps: the token stays out of encrypted backups and can't be moved to another device, with no impact on normal usage.
- If your app calls Rio from background tasks that may run while the device is locked (silent push, background fetch), prefer `.afterFirstUnlockThisDeviceOnly` instead.
- The accessibility level is applied on the next token write. Since tokens are refreshed periodically, existing installs migrate to the new level automatically shortly after the app starts using it.

## Authenticate 

Rio client's authenticateWithCustomToken method should be used to authenticate a user. If you don't call this method, client will send actions as an anonymous user.

```swift
rio.authenticateWithCustomToken(customToken)
```

You can sign out with .signout method.

```swift
rio.signOut()
```

## Rio Delegate

You can attach a delegate to Rio client.

```swift
rio.delegate = self
```

And start receiving authentication state changes.

```swift
extension ViewController : RioClientDelegate {
    func rioClient(client: Rio, authStatusChanged toStatus: RioClientAuthStatus) {
        
    }
}
```

## Get a cloud object

```swift
rio.getCloudObject(with: RioCloudObjectOptions(classID: "Test", useLocal: false)) { object in
    
    print("InstanceId is \(object.instanceId)")
    
} onError: { error in
    
}
```

`useLocal` is optional and `nil` behaves like `false`. Writing it out is still
worthwhile in `getCloudObject`: the flag decides whether the SDK makes an
`rbs.core.request.INSTANCE` round trip, which is a choice worth seeing at the
call site.

### useLocal

`useLocal: false` instantiates the object on the server: a request that returns
the instance's `methods`, `response` and `isNewInstance`, and reports
`cloudObjectNotFound` if the instance does not exist.

`useLocal: true` builds the handle on the device with no request. It needs an
`instanceID`, which comes from a previous remote instantiation as
`object.instanceId`:

```swift
if let cachedInstanceId {
    rio.getCloudObject(with: RioCloudObjectOptions(
        classID: "Test",
        instanceID: cachedInstanceId,
        useLocal: true
    )) { object in
        
    } onError: { error in
        
    }
}
```

Two things to know:

- A locally built object has no `methods`, `response` or `isNewInstance` — those
  only come from the server. `call`, `state` and `listInstances` still work; they
  go to the network on their own.
- `useLocal: true` without an `instanceID` is ignored: the SDK instantiates
  remotely instead, which on a first launch creates a new instance and returns its
  id. So the usual shape is to instantiate remotely once, keep the id, and use the
  local path afterwards.

`useLocal` is only read by `getCloudObject`. `call`, `listInstances` and
`makeStaticCall` accept it because they share the options type, but ignore its
value.

## Call a method on a cloud object

```swift
object.call(with: RioCloudObjectOptions(method: "sayHello")) { resp in
    
} onError: { error in
    
}
```

Leave `useLocal` out here, or pass `false`. A method call goes to the network
either way, so `true` would compile, be ignored, and leave a promise in the source
that the call does not keep. The same holds for `listInstances` and
`makeStaticCall`.

Note that this is true of a locally built object too: `useLocal: true` skips the
request that produces the handle, not the requests its methods make.

## Listen to realtime updates on cloud objects

```swift
object.state?.public.subscribe(onSuccess: { data in
    
}, onError: { err in
    
})
```

## Migrating to 0.1.0

0.1.0 raises the minimum iOS version and the Firebase major. Read this section even
if you do not use Firebase directly: it is a security fix, not a routine bump. The
`RioCloudObjectOptions` API is unchanged, so existing call sites compile as they are.

### Firebase 12.19.3 and iOS 15 (security fix)

Private keys of several eMudhra intermediate certificate authorities were
compromised in October 2026. FirebaseFirestore 13.1.0 and earlier (except 12.19.3)
still trust certificates chained to them, so an attacker on the network can
impersonate the Firestore backend that Rio uses for cloud object listeners. Google's
guide is at
https://firebase.google.com/support/guides/compromised-emudhra-intermediate-ca#apple-native-apps-firestore.

The fix is only in the client SDK, so every installed build stays exposed until it
is replaced. Rio 0.1.0 therefore requires:

- **Firebase `>= 12.19.3, < 13`.** Firebase 13 is not published to CocoaPods, and 12
  is the last major that is, so 12.19.3 is the floor on both package managers. If your
  Podfile pins `Firebase/*` to `~> 11.x`, raise those pins to `~> 12.19.3`; every other
  Firebase pod in the app (Analytics, Crashlytics, Messaging, Remote Config, ...) moves
  to 12 with them.
- **iOS 15.0** as the deployment target, because Firebase 12 does not build for
  anything lower. Set `platform :ios, '15.0'` in the Podfile and raise
  `IPHONEOS_DEPLOYMENT_TARGET` in the project.

Firebase 12 removed a few APIs Rio never used; the ones most likely to show up in an
app are Dynamic Links (`ActionCodeSettings.dynamicLinkDomain`) and
`FirebaseOptions.deepLinkURLScheme` / `androidClientID` / `trackingID`.

After updating, ship a new build and get users onto it. Nothing on the server side
or in the OS closes the hole for builds already installed.

```ruby
pod 'Rio', '~> 0.1.0'
```

```swift
.package(url: "https://github.com/rettersoft/rio-ios-sdk", from: "0.1.0")
```

## License

Rio is available under the MIT license. See the LICENSE file for more info.



