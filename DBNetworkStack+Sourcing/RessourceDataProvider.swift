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

public enum ResourceDataProviderState {
    case Success
    case Error
    case Loading
    case Empty
    
    public var isLoading: Bool {
        return self == .Loading
    }
}

/**
 `ResourceDataProvider` provides fetching JSONResources and transforming them into a DataProvider(DataSource) for colllection/table views.
 */
final public class ResourceDataProvider<Resource: ArrayResourceModeling>: NSObject, ArrayDataProviding {
    
    public typealias Object = Resource.Element
    public var whenStateChanges: ((ResourceDataProviderState) -> ())?
    public let sectionIndexTitles: Array<String>? = nil
    public var data: Array<Array<Object>> {
        guard let fetchedData = fetchedData else {
            return []
        }
        return [fetchedData as! Array<Object>]
    }
    
    /// Describes the current stae of the data provider. Listen for state changes with the `whenStateChanges` callback
    public private(set) var state: ResourceDataProviderState = .Empty {
        didSet {
            whenStateChanges?(state)
        }
    }
    private(set) var resource: Resource?
    
    private var fetchedData: Resource.Model?
    private let dataProviderDidUpdate: (([DataProviderUpdate<Object>]?) ->())?
    
    // MARK: Network properties
    private let networkService: NetworkServiceProviding
    private var currentRequest: NetworkTaskRepresenting?
    
    /**
     Creates an instance which fetches a gives resource
     
     - parameter resource: The resource to fetch. 
     - parameter networkService: a networkservice for fetching resources
     - parameter dataProviderDidUpdate: handler for data updates. `nil` by default.
     - parameter mapFetchedObjectToArray: A function which maps a object to an array for using it as a dataSoruce. `nil` by default.
     - parameter delegate: A delegate for listing to events. `nil` by default.
     */
    public init(resource: Resource?, networkService: NetworkServiceProviding, dataProviderDidUpdate: @escaping (([DataProviderUpdate<Object>]?) ->()), whenStateChanges: ((ResourceDataProviderState) -> ())? = nil) {
        self.resource = resource
        self.dataProviderDidUpdate = dataProviderDidUpdate
        self.networkService = networkService
        self.whenStateChanges = whenStateChanges
        super.init()
        fetchResource()
    }
    
    /**
     Fetches a new resource.
     
     - parameter resource: The new resource to fetch.
    */
    public func reconfigureData(resource: Resource?) {
        if resource == nil {
            fetchedData = nil
        }
        self.resource = resource
        fetchResource()
    }
    
    //MARK: private
    /**
     Gets called when data updates.
     
     - parameter updates: The updates.
     */
    private func didUpdateData(updates: [DataProviderUpdate<Object>]?) {
        dataProviderDidUpdate?(updates)
    }
    
    /**
     Fetches the resources via webservices.
    */
    private func fetchResource() {
        currentRequest?.cancel()
        guard let resource = resource else {
            state = .Empty
            didUpdateData(updates: nil)
            return
        }
        state = .Loading
        currentRequest = networkService.request(resource, onCompletion: { fetchedData in
            self.currentRequest = nil
            self.fetchedData = fetchedData
            self.didUpdateData(updates: nil)
            self.state = .Success
            }, onError: { error in
                switch error {
                case .requestError(let err):
                    let err = err as NSError
                    if err.code != -999 {
                        self.state = .Error
                    }
                    break
                default:
                    self.state = .Error
                }
                
        })
    }
    
    /**
     Retches the current resources via webservices. 
     Can be helpfull when connection lost and you want to try
     */
    public func retry() {
        fetchResource()
    }
}

