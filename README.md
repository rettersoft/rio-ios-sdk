
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
rio.getCloudObject(with: RioCloudObjectOptions(classID: "Test")) { object in
    
} onError: { error in
    
}
```

## Call a method on a cloud object

```swift
object.call(with: RioCloudObjectOptions(method: "sayHello")) { resp in
    
} onError: { error in
    
}
```

## Listen to realtime updates on cloud objects

```swift
object.state?.public.subscribe(onSuccess: { data in
    
}, onError: { err in
    
})
```

## License

Rio is available under the MIT license. See the LICENSE file for more info.



