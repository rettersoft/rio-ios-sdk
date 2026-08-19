
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

You can use swift package manager with following repo url and using main branch:

```
https://github.com/rettersoft/rio-ios-sdk
```

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

`useLocal` has no default, so every options value states it. The flag decides
whether the SDK makes an `rbs.core.request.INSTANCE` round trip, which is a
choice worth seeing at the call site.

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
`makeStaticCall` require it because they share the options type, but ignore its
value.

## Call a method on a cloud object

```swift
object.call(with: RioCloudObjectOptions(method: "sayHello", useLocal: false)) { resp in
    
} onError: { error in
    
}
```

Always pass `useLocal: false` here. A method call goes to the network either way,
so `true` would compile, be ignored, and leave a promise in the source that the
call does not keep. The same holds for `listInstances` and `makeStaticCall`.

Note that this is true of a locally built object too: `useLocal: true` skips the
request that produces the handle, not the requests its methods make.

## Listen to realtime updates on cloud objects

```swift
object.state?.public.subscribe(onSuccess: { data in
    
}, onError: { err in
    
})
```

## Migrating to 0.1.0

**0.1.0 is not released yet.** It is available as the prerelease `0.1.0-beta.1`
so you can migrate and report problems before the change becomes mandatory.

Nothing changes for you until you ask for it. CocoaPods does not resolve a
prerelease unless the requirement names one, so `pod 'Rio'`, `pod 'Rio', '~> 0.0.68'`
and `pod 'Rio', '~> 0.1'` all keep giving you 0.0.68.

To try the beta, name the version explicitly:

```ruby
pod 'Rio', '0.1.0-beta.1'
```

With Swift Package Manager, point at the tag. The `main` branch that the
installation section recommends still carries 0.0.68, so following those
instructions does not pull the beta either:

```swift
.package(url: "https://github.com/rettersoft/rio-ios-sdk", .exact("0.1.0-beta.1"))
```

The API in the beta is what 0.1.0 will ship, so migrating now is not throwaway
work.

---

`useLocal` changed from `Bool?` to `Bool` and has no default, so **every**
`RioCloudObjectOptions` must state it. That is the point: the flag decides whether
a network round trip happens, and it was the one field you could forget about and
still compile — while forgetting it selected the request.

The first item below is a compile error, so the compiler lists your call sites. The
second is mostly a compile error, with one case that only warns.

### Add `useLocal` to every options value

It sits between `path` and `isStaticMethod` in the initializer, so existing
arguments keep their order — you insert one argument rather than rewriting the
call.

```swift
// before
RioCloudObjectOptions(classID: "Test")
RioCloudObjectOptions(method: "sayHello", culture: "tr-TR")
RioCloudObjectOptions(classID: "Test", method: "staticHello")

// after
RioCloudObjectOptions(classID: "Test", useLocal: false)
RioCloudObjectOptions(method: "sayHello", useLocal: false, culture: "tr-TR")
RioCloudObjectOptions(classID: "Test", method: "staticHello", useLocal: false)
```

`call`, `listInstances` and `makeStaticCall` need it too even though they ignore
its value, because they share the options type. Pass `false` — a method call
reaches the network either way. This applies to options with no other arguments as
well:

```swift
// before
object.listInstances(with: RioCloudObjectOptions())

// after
object.listInstances(with: RioCloudObjectOptions(useLocal: false))
```

Do not migrate by grepping for `RioCloudObjectOptions(` — that misses call sites
written with the implicit form, which are easy to have and just as broken:

```swift
rio.makeStaticCall(with: .init(classID: "Example", method: "Method", useLocal: false))
rio.getCloudObject(with: .init(classID: "CMS", instanceID: "default", useLocal: true))
```

Build instead and work through the errors; the compiler finds every form.

Runtime behavior does not change: `nil` and `false` were already the same thing,
so `useLocal: false` preserves exactly what omitting it used to do.

### Treating `useLocal` as an optional

`nil` and `false` were indistinguishable at runtime, so these checks were never
doing anything:

```swift
// before
if let useLocal = options.useLocal, useLocal { ... }
if options.useLocal == nil { ... }

// after
if options.useLocal { ... }
```

`if let` and assigning `nil` are compile errors. Comparing to `nil` still
compiles, with a warning that it always returns the same value:

```
warning: comparing non-optional value of type 'Bool' to 'nil' always returns false
```

Treat that warning as an error to fix — the branch it guards can no longer run.

## License

Rio is available under the MIT license. See the LICENSE file for more info.



