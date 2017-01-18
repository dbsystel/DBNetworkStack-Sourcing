# DBNetworkStack-Sourcing

This component acts as a bridge between [Sourcing](https://github.com/lightsprint09/Sourcing) and [DBNetworkStack](https://github.com/dbsystel/DBNetworkStack). It is a data provider, for resources fetched by a network service provider. 

## Loading
```swift
import DBNetworkStackSourcing
import DBNetworkStack
import Sourcing

let networkService: NetworkServiceProviding = // Network service which implements DBNetworkStack.NetworkServiceProviding
let resource = // Some resource which implements DBNetworkStack.ArrayResourceProviding

let dataSource: TableViewDataSource<ResourceDataProvider<Int>, CellConfiguration<Int>> = //

let ressourceDataProvider = ResourceDataProvider(resource: resource, networkService: networkService,
            dataProviderDidUpdate: { [weak self] updates in
                                    self?.dataSource.processUpdates(updates)
            }, whenStateChanges: { newState in })
        
// Start loading content
ressourceDataProvider.load()
```

## Access state of the loading operation
You can either pass a closure into `ResourceDataProvider.init` and get notified when state changes or you could access `ressourceDataProvider.state`.

## Default data
If you have default local data you can provide it upfront. It will be replaced with data from the network once the requests is done.
```swift
 ressourceDataProvider = ResourceDataProvider(
            resource: nil, prefetchedData: [1, 2, 3],
            networkService: networkService,
            dataProviderDidUpdate: {  _ in },
            whenStateChanges: { _ in }
 )
```

## Sorting loaded data
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
