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
                                                     networkService: networkService, dataProviderDidUpdate: {  _ in }, whenStateChanges: { _ in })
