//
//  Copyright (C) DB Systel GmbH.
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
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
    public let sectionIndexTitles: [String]? = nil
    
    /// The provided data
    open var contents: [[Object]] = []
    /// Describes the current state of the data provider. Listen for state changes with the `whenStateChanges` callback
    public internal(set) var state: ResourceDataProviderState = .empty {
        didSet { whenStateChanges?(state) }
    }
    private var stateBeforeLoadingStarted: ResourceDataProviderState = .empty
    private var resource: Resource<[[Object]]>?
    
    public var dataProviderDidUpdate: ProcessUpdatesCallback<Object>?
    /// Closure which gets called, when a data inside the provider changes and those changes should be propagated to the datasource.
    /// **Warning:** Only set this when you are updating the datasource.
    public var whenDataProviderChanged: ProcessUpdatesCallback<Object>?
    
    // MARK: Network properties
    private let networkService: NetworkServiceProviding
    private var currentRequest: NetworkTaskRepresenting?
    
    /**
     Creates an instance which fetches a given resource and exposes the result as a DataProvider.
     
     - parameter resource: The resource to fetch.
     - parameter networkService: a networkservice for fetching resources
     - parameter whenStateChanges: Register for state changes with a given block.
     */
    public init(resource: Resource<[[Object]]>, networkService: NetworkServiceProviding,
                whenStateChanges: @escaping ((ResourceDataProviderState) -> Void)) {
        self.resource = resource
        self.networkService = networkService
        self.whenStateChanges = whenStateChanges
    }
    
    /**
     Creates an instance which fetches a given resource and exposes the result as a DataProvider.
     
     - parameter networkService: a networkservice for fetching resources
     - parameter whenStateChanges: Register for state changes with a given block.
     */
    public init(networkService: NetworkServiceProviding,
                whenStateChanges: @escaping ((ResourceDataProviderState) -> Void)) {
        self.resource = nil
        self.networkService = networkService
        self.whenStateChanges = whenStateChanges
    }
    
    /**
     Creates an instance which fetches a gives resource and exposes the result as a DataProvider.
     
     - parameter resource: The resource to fetch.
     - parameter networkService: a networkservice for fetching resources
     - parameter whenStateChanges: Register for state changes with a given block.
     */
    public convenience init(resource: Resource<[Object]>, networkService: NetworkServiceProviding,
                            whenStateChanges: @escaping ((ResourceDataProviderState) -> Void)) {
        let twoDimensionalResource = resource.map { [$0] }
        self.init(resource: twoDimensionalResource, networkService: networkService, whenStateChanges: whenStateChanges)
    }
    
    /// Clears all content and changes state to `.empty`
    public func clear() {
        resource = nil
        contents = []
        load(skipLoadingState: false)
    }
    
    /**
     Replaces the current resource with a new one. It directly triggers a reload.
     
     If you want to silently change the contents by fetching a different resource you should `skipLoadingState: true`.
     This prevents `ResourceDataProvider` to switch in the loding state. After content change notification gets trigged.
     
     - parameter resource: The new resource to fetch.
     - parameter skipLoadingState: when true the loading state will be skipped. Defaults to false
     */
    public func reconfigure(with resource: Resource<[[Object]]>, skipLoadingState: Bool = false) {
        self.resource = resource
        load(skipLoadingState: skipLoadingState)
    }
    
    /**
     Replaces the current resource with a new one. It directly triggers a reload.
     
     If you want to silently change the contents by fetching a different resource you should `skipLoadingState: true`.
     This prevents `ResourceDataProvider` to switch in the loding state. After content change notification gets trigged.
     
     - parameter resource: The new resource to fetch.
     - parameter skipLoadingState: when true the loading state will be skipped. Defaults to false
     */
    public func reconfigure(with resource: Resource<[Object]>, skipLoadingState: Bool = false) {
        let twoDimensionalResource = resource.map { [$0] }
        reconfigure(with: twoDimensionalResource, skipLoadingState: skipLoadingState)
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
            dataProviderDidChangeContent()
            return
        }
        
        currentRequest = networkService.request(resource, onCompletion: loadDidSucess, onError: loadDidError)
        if let currentRequest = currentRequest, !skipLoadingState {
            state = .loading(currentRequest)
        }
    }
    
    private func loadDidSucess(with result: [[Object]]) {
        currentRequest = nil
        contents = result
        state = .success
        dataProviderDidChangeContent()
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
    private func dataProviderDidChangeContent() {
        dataProviderDidUpdate?(nil)
        whenDataProviderChanged?(nil)
    }
}
