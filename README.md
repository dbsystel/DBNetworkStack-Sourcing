[![Build Status](https://travis-ci.org/dbsystel/DBNetworkStack-Sourcing.svg?branch=develop)](https://travis-ci.org/dbsystel/DBNetworkStack-Sourcing)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![codecov](https://codecov.io/gh/dbsystel/DBNetworkStack-Sourcing/branch/develop/graph/badge.svg)](https://codecov.io/gh/dbsystel/DBNetworkStack-Sourcing)

# DBNetworkStack-Sourcing

This component acts as a bridge between [Sourcing](https://github.com/lightsprint09/Sourcing) and [DBNetworkStack](https://github.com/dbsystel/DBNetworkStack). It is a data provider, for resources fetched by a network service. 

## Usage
```swift
import Sourcing
import DBNetworkStack
import DBNetworkStackSourcing

let networkService: NetworkServiceProviding = //
let resource: Resource<[Int]> = //

let resourceDataProvider = ResourceDataProvider<Int>(resource: resource, networkService: networkService, whenStateChanges: { state in
        //handle state change
})
        
// Start loading content
resourceDataProvider.load()
```

### Access state of the loading operation
You can either pass a closure into `ResourceDataProvider.init` and get notified when state changes or you could access `ressourceDataProvider.state`.

### Reloading a resource
```swift
let newResource: Resource<[Int]> = //
resourceDataProvider.reconfigure(with: newResource)
```

Somtimes it can be handy to skip the state of loading (e.g when inital loading displays a spinner and following reloads should not)
```swift
let newResource: Resource<[Int]> = //
resourceDataProvider.reconfigure(with: newResource, skipLoadingState: true)
```
**skipLoadingState is availaibe in initial `load()` as well**

### Accessing current contents
```swift
resourceDataProvider.contents
```

## Requirements
- iOS 9.0+
- Xcode 9.0+
- Swift 4.0

## Installation

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

Specify the following in your `Cartfile`:

```ogdl
github "dbsystel/DBNetworkStack-Sourcing" ~> 0.9
```
## Contributing
Feel free to submit a pull request with new features, improvements on tests or documentation and bug fixes. Keep in mind that we welcome code that is well tested and documented.

## Contact
Lukas Schmidt ([Mail](mailto:lukas.la.schmidt@deutschebahn.com), [@lightsprint09](https://twitter.com/lightsprint09)), 
Christian Himmelsbach ([Mail](mailto:christian.himmelsbach@deutschebahn.com))

## License
DBNetworkStack-Sourcing is released under the MIT license. See LICENSE for details.
