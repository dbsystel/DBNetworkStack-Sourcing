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
    
    /// Function which gets called when state changes
    public var whenStateChanges: ((ResourceDataProviderState) -> Void)?
    
    /// Section Index Titles for `UITableView`. Related to `UITableViewDataSource` method `sectionIndexTitlesForTableView`
    public let sectionIndexTitles: Array<String>? = nil
    
    /// The provided data
    open var contents: Array<Array<Object>> = []
    /// Describes the current stae of the data provider. Listen for state changes with the `whenStateChanges` callback
    public internal(set) var state: ResourceDataProviderState = .empty {
        didSet { whenStateChanges?(state) }
    }
    private var stateBeforeLoadingStarted: ResourceDataProviderState = .empty
    private var resource: Resource<Array<Object>>?
    
    public var dataProviderDidUpdate: ProcessUpdatesCallback<Object>?
    /// Closure which gets called, when a data inside the provider changes and those changes should be propagated to the datasource.
    /// **Warning:** Only set this when you are updating the datasource.
    public var whenDataProviderChanged: ProcessUpdatesCallback<Object>?
    
    // MARK: Network properties
    private let networkService: NetworkServiceProviding
    private var currentRequest: NetworkTaskRepresenting?
    
    /**
     Creates an instance which fetches a gives resource and exposes the result as a DataProvider.
     
     - parameter resource: The resource to fetch.
     - parameter networkService: a networkservice for fetching resources
     - parameter whenStateChanges: Register for state changes with a given block.
     */
    public init(resource: Resource<Array<Object>>?, networkService: NetworkServiceProviding,
                whenStateChanges: @escaping ((ResourceDataProviderState) -> Void)) {
        self.resource = resource
        self.networkService = networkService
        self.whenStateChanges = whenStateChanges
    }
    
    /**
     Fetches a new resource.
     
     - parameter resource: The new resource to fetch.
     - parameter skipLoadingState: when true the loading state will be skipped. Defaults to false
     */
    public func reconfigure(with resource: Resource<Array<Object>>?, skipLoadingState: Bool = false) {
        if resource == nil {
            contents = []
        }
        self.resource = resource
        load(skipLoadingState: skipLoadingState)
    }
    
    /**
     Fetches the current resources via webservices.
     
      - parameter skipLoadingState: when true the loading state will be skipped. Defaults to false.
     */
    public func load(skipLoadingState: Bool = false) {
        stateBeforeLoadingStarted = state
        currentRequest?.cancel()
        guard let resource = resource else {
            state = .empty
            dataProviderDidChangeContets(with: nil)
            return
        }
        if !skipLoadingState {
            state = .loading
        }
        currentRequest = networkService.request(resource, onCompletion: loadDidSucess, onError: loadDidError)
    }
    
    private func loadDidSucess(with result: Array<Object>) {
        currentRequest = nil
        contents = [result]
        state = .success
        dataProviderDidChangeContets(with: nil)
    }

    /// Handles errors which occur during fetching a resource.
    ///
    /// - Parameter error: the error which occurs.
    private func loadDidError(with error: NetworkError) {
        if case .cancelled = error {
            state = stateBeforeLoadingStarted
            return
        }
        state = .error(error)
    }
    
    /**
     Gets called when data updates.
     
     - parameter updates: The updates.
     */
    private func dataProviderDidChangeContets(with updates: [DataProviderUpdate<Object>]?) {
        dataProviderDidUpdate?(updates)
        whenDataProviderChanged?(updates)
    }
}
