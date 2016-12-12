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

extension ArrayResourceModeling {
    
    
    /// Wraps self insie a standart resource 
    ///
    /// - Returns: the wrapped resource
    func wrapped() -> Resource<Array<Element>> {
        let resource = Resource<Model>(request: request, parse: parse)
        return resource as! Resource<Array<Element>>
    }
}

/**
 `ResourceDataProvider` provides fetching JSONResources and transforming them into a DataProvider(DataSource) for colllection/table views.
 */
final public class ResourceDataProvider<Object>: ArrayDataProviding {

    public var sortDescriptor: ((Object, Object) -> Bool)?
    public var whenStateChanges: ((ResourceDataProviderState) -> ())?
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
    fileprivate let dataProviderDidUpdate: (([DataProviderUpdate<Object>]?) ->())?
    
    // MARK: Network properties
    fileprivate let networkService: NetworkServiceProviding
    fileprivate var currentRequest: NetworkTaskRepresenting?
    
    /**
     Creates an instance which fetches a gives ressource
     
     - parameter ressource: The ressource to fetch.
     - parameter networkService: a networkservice for fetching ressources
     - parameter dataProviderDidUpdate: handler for data updates. `nil` by default.
     - parameter mapFetchedObjectToArray: A function which maps a object to an array for using it as a dataSoruce. `nil` by default.
     - parameter delegate: A delegate for listing to events. `nil` by default.
     */
    public init(ressource: Resource<Array<Object>>?, networkService: NetworkServiceProviding, dataProviderDidUpdate: @escaping (([DataProviderUpdate<Object>]?) ->()), whenStateChanges: @escaping ((ResourceDataProviderState) -> ())) {
        self.resource = ressource
        self.dataProviderDidUpdate = dataProviderDidUpdate
        self.networkService = networkService
        self.whenStateChanges = whenStateChanges
    }
    
    /**
     Fetches a new ressource.
     
     - parameter ressource: The new ressource to fetch.
     */
    public func reconfigure(_ resource: Resource<Array<Object>>?) {
        if resource == nil {
            fetchedData = nil
        }
        self.resource = resource
        load()
    }
    
    //MARK: private
    /**
     Gets called when data updates.
     
     - parameter updates: The updates.
     */
    fileprivate func didUpdate(_ updates: [DataProviderUpdate<Object>]?) {
        dataProviderDidUpdate?(updates)
    }
    
    /**
     Fetches the current ressources via webservices.
     */
    fileprivate func load() {
        currentRequest?.cancel()
        guard let ressource = resource else {
            state = .empty
            didUpdate(nil)
            return
        }
        state = .loading
        currentRequest = networkService.request(ressource, onCompletion: loadDidSucess, onError: loadDidError)
    }
    
    fileprivate func loadDidSucess(fetchedData: Array<Object>) {
        self.currentRequest = nil
        if let sortDescriptor = self.sortDescriptor {
            self.fetchedData = fetchedData.sorted(by: sortDescriptor)
        } else {
            self.fetchedData = fetchedData
        }
        
        self.state = .success
        self.didUpdate(nil)
    }
    
    fileprivate func loadDidError(error: DBNetworkStackError) {
        switch error {
        case .requestError(let errorResult):
            if (errorResult as NSError).code != -999 {
                self.state = .error(error)
            }
            break
        default:
            self.state = .error(error)
        }
    }
}

public extension ResourceDataProvider {
    /**
     Creates an instance which fetches a gives array ressource
     
     - parameter ressource: The array ressource to fetch.
     - parameter networkService: a networkservice for fetching ressources
     - parameter dataProviderDidUpdate: handler for data updates. `nil` by default.
     - parameter mapFetchedObjectToArray: A function which maps a object to an array for using it as a dataSoruce. `nil` by default.
     - parameter delegate: A delegate for listing to events. `nil` by default.
     */
    public convenience init<ArrayResource: ArrayResourceModeling>(ressource: ArrayResource?, networkService: NetworkServiceProviding, dataProviderDidUpdate: @escaping (([DataProviderUpdate<Object>]?) ->()), whenStateChanges: @escaping ((ResourceDataProviderState) -> ())) where ArrayResource.Element == Object {
        self.init(ressource: ressource?.wrapped(), networkService: networkService, dataProviderDidUpdate: dataProviderDidUpdate, whenStateChanges: whenStateChanges)
    }
    
    /**
     Fetches a new ressource.
     
     - parameter ressource: The new ressource to fetch.
     */
    public func reconfigure<ArrayResource: ArrayResourceModeling>(_ resource: ArrayResource?) where ArrayResource.Element == Object {
        reconfigure(resource?.wrapped())
    }
}


