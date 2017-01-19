//
//  JSONListResourceDataProvider.swift
//  BFACore
//
//	Legal Notice! DB Systel GmbH proprietary License!
//
//	Copyright (C) 2015 DB Systel GmbH
//	DB Systel GmbH; Jürgen-Ponto-Platz 1; D-60329 Frankfurt am Main; Germany; http://www.dbsystel.de/

//	This code is protected by copyright law and is the exclusive property of
//	DB Systel GmbH; Jürgen-Ponto-Platz 1; D-60329 Frankfurt am Main; Germany; http://www.dbsystel.de/

//	Consent to use ("licence") shall be granted solely on the basis of a
//	written licence agreement signed by the customer and DB Systel GmbH. Any
//	other use, in particular copying, redistribution, publication or
//	modification of this code without written permission of DB Systel GmbH is
//	expressly prohibited.

//	In the event of any permitted copying, redistribution or publication of
//	this code, no changes in or deletion of author attribution, trademark
//	legend or copyright notice shall be made.
//
//  Created by Lukas Schmidt on 01.08.16.
//

import Foundation
import Sourcing
import DBNetworkStack

/**
 `ResourceDataProvider` provides fetching JSONResources and transforming them into a DataProvider(DataSource) for colllection/table views.
 */
public class ResourceDataProvider<Object>: ArrayDataProviding {
    
    /// Data which get provided when in no data is fetched
    public var prefetchedData: [Object] = []
    
    /// Function which sorts the result of the ressource
    public var sortDescriptor: ((Object, Object) -> Bool)?
    
    /// Function which gets called when state changes
    public var whenStateChanges: ((ResourceDataProviderState) -> Void)?
    
    /// Section Index Titles for `UITableView`. Related to `UITableViewDataSource` method `sectionIndexTitlesForTableView`
    public let sectionIndexTitles: Array<String>? = nil
    
    /// The provided data
    open var data: Array<Array<Object>> {
        return [fetchedData ?? prefetchedData]
    }
    
    /// Describes the current stae of the data provider. Listen for state changes with the `whenStateChanges` callback
    public internal(set) var state: ResourceDataProviderState = .empty {
        didSet { whenStateChanges?(state) }
    }
    var resource: Resource<Array<Object>>?
    
    var fetchedData: Array<Object>?
    let dataProviderDidUpdate: (([DataProviderUpdate<Object>]?) -> Void)?
    
    // MARK: Network properties
    let networkService: NetworkServiceProviding
    var currentRequest: NetworkTaskRepresenting?
    
    /**
     Creates an instance which fetches a gives resource and exposes the result as a DataProvider.
     
     - parameter resource: The resource to fetch.
     - parameter prefetchedData: Data which is already in memory, like cached data.
     - parameter networkService: a networkservice for fetching resources
     - parameter dataProviderDidUpdate: handler for data updates. `nil` by default.
     - parameter mapFetchedObjectToArray: A function which maps a object to an array for using it as a dataSoruce. `nil` by default.
     - parameter delegate: A delegate for listing to events. `nil` by default.
     */
    public init(resource: Resource<Array<Object>>?, prefetchedData: [Object] = [], networkService: NetworkServiceProviding,
                dataProviderDidUpdate: @escaping (([DataProviderUpdate<Object>]?) -> Void),
                whenStateChanges: @escaping ((ResourceDataProviderState) -> Void)) {
        self.resource = resource
        self.prefetchedData = prefetchedData
        self.dataProviderDidUpdate = dataProviderDidUpdate
        self.networkService = networkService
        self.whenStateChanges = whenStateChanges
        if !prefetchedData.isEmpty {
            self.state = .success
        }
    }
    
    /**
     Fetches a new resource.
     
     - parameter resource: The new resource to fetch.
     - parameter clearBeforeLoading: when true the loading state will be skipped.
     */
    public func reconfigure(with resource: Resource<Array<Object>>?, clearBeforeLoading: Bool = true) {
        if resource == nil {
            fetchedData = nil
        }
        self.resource = resource
        load(clearBeforeLoading: clearBeforeLoading)
    }
    
    // MARK: private
    /**
     Gets called when data updates.
     
     - parameter updates: The updates.
     */
    func didUpdate(_ updates: [DataProviderUpdate<Object>]?) {
        dataProviderDidUpdate?(updates)
    }
    
    /**
     Fetches the current resources via webservices.
     
      - parameter clearBeforeLoading: when true the loading state will be skipped.
     */
    public func load(clearBeforeLoading: Bool = true) {
        currentRequest?.cancel()
        guard let resource = resource else {
            state = .empty
            didUpdate(nil)
            return
        }
        if clearBeforeLoading {
            state = .loading
        }
        currentRequest = networkService.request(resource, onCompletion: loadDidSucess, onError: loadDidError)
    }
    
    func loadDidSucess(with newFetchedData: Array<Object>) {
        currentRequest = nil
        if let sortDescriptor = sortDescriptor {
            fetchedData = newFetchedData.sorted(by: sortDescriptor)
        } else {
            fetchedData = newFetchedData
        }
        
        state = .success
        didUpdate(nil)
    }

    /// Handles errors which occur during fetching a resource.
    ///
    /// - Parameter error: the error which occurs.
    func loadDidError(with error: DBNetworkStackError) {
        state = .error(error)
    }
}

public extension ResourceDataProvider {
    /**
     Creates an instance which fetches a gives array resource and exposes the result as a DataProvider.
     
     - parameter resource: The array resource to fetch.
     - parameter prefetchedData: Data which is already in memory, like cached data.
     - parameter networkService: a networkservice for fetching resources
     - parameter dataProviderDidUpdate: handler for data updates. `nil` by default.
     - parameter mapFetchedObjectToArray: A function which maps a object to an array for using it as a dataSoruce. `nil` by default.
     - parameter delegate: A delegate for listing to events. `nil` by default.
     */
    public convenience init<ArrayResource: ArrayResourceModeling>(resource: ArrayResource?, prefetchedData: [Object] = [],
                            networkService: NetworkServiceProviding, dataProviderDidUpdate: @escaping (([DataProviderUpdate<Object>]?) -> Void),
                            whenStateChanges: @escaping ((ResourceDataProviderState) -> Void)) where ArrayResource.Element == Object {
        // swiftlint:disable:next force_cast
        let resource = resource?.wrapped() as! Resource<Array<Object>>
        self.init(resource: resource, prefetchedData: prefetchedData, networkService: networkService,
                  dataProviderDidUpdate: dataProviderDidUpdate, whenStateChanges: whenStateChanges)
    }
    
    /**
     Fetches a new resource.
     
     - parameter resource: The new resource to fetch.
     - parameter clearBeforeLoading: when true the loading state will be skipped.
     */
    public func reconfigure<ArrayResource: ArrayResourceModeling>(with resource: ArrayResource?, clearBeforeLoading: Bool = true)
        where ArrayResource.Element == Object {
        // swiftlint:disable:next force_cast
        let resource = resource?.wrapped() as! Resource<Array<Object>>
        reconfigure(with: resource, clearBeforeLoading: clearBeforeLoading)
    }
}
