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
final public class ResourceDataProvider<Object>: ArrayDataProviding {

    public var sortDescriptor: ((Object, Object) -> Bool)?
    public var whenStateChanges: ((ResourceDataProviderState) -> Void)?
    public let sectionIndexTitles: Array<String>? = nil
    public var data: Array<Array<Object>> {
        return [fetchedData ?? []]
    }
    
    /// Describes the current stae of the data provider. Listen for state changes with the `whenStateChanges` callback
    public fileprivate(set) var state: ResourceDataProviderState = .empty {
        didSet {
            whenStateChanges?(state)
        }
    }
    fileprivate(set) var resource: Resource<Array<Object>>?
    
    fileprivate var fetchedData: Array<Object>?
    fileprivate let dataProviderDidUpdate: (([DataProviderUpdate<Object>]?) -> Void)?
    
    // MARK: Network properties
    fileprivate let networkService: NetworkServiceProviding
    fileprivate var currentRequest: NetworkTaskRepresenting?
    
    /**
     Creates an instance which fetches a gives resource
     
     - parameter resource: The resource to fetch.
     - parameter networkService: a networkservice for fetching resources
     - parameter dataProviderDidUpdate: handler for data updates. `nil` by default.
     - parameter mapFetchedObjectToArray: A function which maps a object to an array for using it as a dataSoruce. `nil` by default.
     - parameter delegate: A delegate for listing to events. `nil` by default.
     */
    public init(resource: Resource<Array<Object>>?, networkService: NetworkServiceProviding,
                dataProviderDidUpdate: @escaping (([DataProviderUpdate<Object>]?) -> Void),
                whenStateChanges: @escaping ((ResourceDataProviderState) -> Void)) {
        self.resource = resource
        self.dataProviderDidUpdate = dataProviderDidUpdate
        self.networkService = networkService
        self.whenStateChanges = whenStateChanges
    }
    
    /**
     Fetches a new resource.
     
     - parameter resource: The new resource to fetch.
     - parameter clearBeforeLoading: when true the loading state will be skipped.
     */
    public func reconfigure(_ resource: Resource<Array<Object>>?, clearBeforeLoading: Bool = true) {
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
    fileprivate func didUpdate(_ updates: [DataProviderUpdate<Object>]?) {
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
    
    fileprivate func loadDidSucess(fetchedData: Array<Object>) {
        self.currentRequest = nil
        if let sortDescriptor = sortDescriptor {
            self.fetchedData = fetchedData.sorted(by: sortDescriptor)
        } else {
            self.fetchedData = fetchedData
        }
        
        self.state = .success
        self.didUpdate(nil)
    }
    
    fileprivate func loadDidError(error: DBNetworkStackError) {
        self.state = .error(error)
    }
}

extension Resource {
    init<AnyRessource: ResourceModeling>(ressource: AnyRessource) where AnyRessource.Model == Model {
        self.parse = ressource.parse
        self.request = ressource.request
    }
}

public extension ResourceDataProvider {
    /**
     Creates an instance which fetches a gives array resource
     
     - parameter resource: The array resource to fetch.
     - parameter networkService: a networkservice for fetching resources
     - parameter dataProviderDidUpdate: handler for data updates. `nil` by default.
     - parameter mapFetchedObjectToArray: A function which maps a object to an array for using it as a dataSoruce. `nil` by default.
     - parameter delegate: A delegate for listing to events. `nil` by default.
     */
    public convenience init<ArrayResource: ArrayResourceModeling>(resource: ArrayResource?, networkService: NetworkServiceProviding,
                            dataProviderDidUpdate: @escaping (([DataProviderUpdate<Object>]?) -> Void),
                            whenStateChanges: @escaping ((ResourceDataProviderState) -> Void)) where ArrayResource.Element == Object {
        let resource: Resource<Array<Object>> = Resource(ressource: resource!)
        self.init(resource: resource, networkService: networkService, dataProviderDidUpdate: dataProviderDidUpdate, whenStateChanges: whenStateChanges)
    }
    
    /**
     Fetches a new resource.
     
     - parameter resource: The new resource to fetch.
      - parameter clearBeforeLoading: when true the loading state will be skipped.
     */
    public func reconfigure<ArrayResource: ArrayResourceModeling>(_ resource: ArrayResource?, clearBeforeLoading: Bool = true)
        where ArrayResource.Element == Object {
        let resource = resource?.wrapped() as! Resource<Array<Object>>
        reconfigure(resource, clearBeforeLoading: clearBeforeLoading)
    }
}
