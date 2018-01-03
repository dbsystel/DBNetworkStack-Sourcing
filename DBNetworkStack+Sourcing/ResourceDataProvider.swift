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
 `ResourceDataProvider` provides fetching resources and transforming them into a data provider. It provides its own state so you can react to it.
 **Example**:
 ```swift
 let networkService: NetworkService = //
 let resource: Resource<[Train]> = //
 
 let dataProvider = ResourceDataProvider(resource: resource, networkService: networkService)
 dataProvider.load()
 ```
 
 */
public class ResourceDataProvider<Object>: ArrayDataProviding {
    public typealias Element = Object
    
    /// Function which gets called when state changes
    public weak var delegate: ResourceDataProviderDelagte?
    
    /// The provided data which was fetched by the resource
    public var content: [[Object]] = []
    
    /// Describes the current state of the data provider. Listen for state changes by implementing `ResourceDataProviderDelagte`.
    public internal(set) var state: ResourceDataProviderState = .empty {
        didSet { delegate?.resourceDataProviderDidChangeState(from: oldValue, to: state) }
    }
    
    /// An observable where you can list on changes for the data provider.
    public var observable: DataProviderObservable {
        return defaultObserver
    }
    
    private var stateBeforeLoadingStarted: ResourceDataProviderState = .empty
    private var resource: Resource<[[Object]]>?
    private let defaultObserver = DefaultDataProviderObservable()
    
    // MARK: Network properties
    private let networkService: NetworkService
    private var currentRequest: NetworkTask?
    
    /**
     Creates an instance with a given resource and exposes the result as a data provider.
     To load the given request you need first reconfigure a resource and call `.load()`.
     
     - parameter networkService: a networkservice for fetching resources
     - parameter whenStateChanges: Register for state changes with a given block.
     - parameter delegate: The delegate of the data provider. Defaults to nil.
     */
    public init(networkService: NetworkService, delegate: ResourceDataProviderDelagte? = nil) {
        self.resource = nil
        self.networkService = networkService
        self.delegate = delegate
    }
    
    /**
     Creates an instance with a given resource and exposes the result as a data provider.
     To load the given request you need to call `.load()`.
     
     - parameter resource: The resource to fetch.
     - parameter networkService: a networkservice for fetching resources
     - parameter delegate: The delegate of the data provider. Defaults to nil.
     */
    public init(resource: Resource<[[Object]]>, networkService: NetworkService, delegate: ResourceDataProviderDelagte? = nil) {
        self.resource = resource
        self.networkService = networkService
        self.delegate = delegate
    }
    
    /**
     Creates an instance which fetches a given resource and exposes the result as a data provider.
     To load the given request you need not call `.load()`.
     
     - parameter resource: The resource to fetch.
     - parameter networkService: a networkservice for fetching resources
     - parameter delegate: The delegate of the data provider. Defaults to nil.
     */
    public convenience init(resource: Resource<[Object]>, networkService: NetworkService, delegate: ResourceDataProviderDelagte? = nil) {
        let twoDimensionalResource = resource.map { [$0] }
        self.init(resource: twoDimensionalResource, networkService: networkService, delegate: delegate)
    }
    
    /// Clears all content and changes state to `.empty`
    public func clear() {
        resource = nil
        content = []
        load(skipLoadingState: false)
    }
    
    /**
     Replaces the current resource with a new one.
     To load the given request you need not call `.load()`.
     
     - parameter resource: The new resource to fetch.
     */
    public func reconfigure(with resource: Resource<[[Object]]>) {
        self.resource = resource
    }
    
    /**
     Replaces the current resource with a new one.
     To load the given request you need not call `.load()`.
     
     - parameter resource: The new resource to fetch.
     */
    public func reconfigure(with resource: Resource<[Object]>) {
        let twoDimensionalResource = resource.map { [$0] }
        reconfigure(with: twoDimensionalResource)
    }
    
    /**
     Fetches the current resources via the network service.
     
     If you want to silently change the content by fetching a different resource you should pass `skipLoadingState: true`.
     This prevents `ResourceDataProvider` to switch into loding state.
     
      - parameter skipLoadingState: when true, the loading state will be skipped. Defaults to false.
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
        content = result
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
    
    /// Gets called when data updates.
    private func dataProviderDidChangeContent() {
        defaultObserver.send(updates: .unknown)
    }
}
