# DBNetworkStack-Sourcing
This provides a dataprovider which will fetch a `Ressource` by using components of the DBNetworkStack.

# Usage
## Loading
```swift
import DBNetworkStackSourcing
import DBNetworkStack
import Sourcing

let networkService: NetworkServiceProviding = //
let resource = // some resource which implements DBNetworkStack.ArrayResourceProviding

let dataSource: TableViewDataSource<ResourceDataProvider<Int>, CellConfiguration<Int>> = //

let ressourceDataProvider = ResourceDataProvider(resource: resource, networkService: networkService, dataProviderDidUpdate: { [weak self] updates in
self?.processUpdates(updates)
            self?.didUpdateContents = true
            }, whenStateChanges: { newState in })
        
// Start loding content
ressourceDataProvider.load()
```

## Access state of loading operation
You can either pass a closure into `ResourceDataProvider.init` and get notified when state changes or you could access `ressourceDataProvider.state`.

## Default data
If you have default local data you can them upfront. It will be replaced with data from the network once the requests is done.
```swift
 ressourceDataProvider = ResourceDataProvider(resource: nil, prefetchedData: [1, 2, 3],
                                                     networkService: networkService, dataProviderDidUpdate: {  _ in },
                                                     whenStateChanges: { _ in })
```

## Sorting loaded data (beta)
Providing a sort descriptor will sort your response.
```swift
ressourceDataProvider.sortDescriptor = { $0 < $1 }
```
## Requirements

- iOS 9.0+
- Xcode 8.0+
- Swift 3.0

## Installation

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

Specify the following in your `Cartfile`:

```ogdl
github "dbsystel/DBNetworkStack-Sourcing" ~> 0.1
```
## Contributing
Feel free to submit a pull request with new features, improvements on tests or documentation and bug fixes. Keep in mind that we welcome code that is well tested and documented.

## Contact
Lukas Schmidt ([Mail](mailto:lukas.la.schmidt@deutschebahn.com), [@lightsprint09](https://twitter.com/lightsprint09)), 
Christian Himmelsbach ([Mail](mailto:christian.himmelsbach@deutschebahn.com))

## License
DBNetworkStack-Sourcing is released under the MIT license. See LICENSE for details.
