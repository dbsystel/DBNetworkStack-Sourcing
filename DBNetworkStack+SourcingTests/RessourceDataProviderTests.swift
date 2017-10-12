//
//  ResourceDataProviderTests.swift
//  BFACore
//
//  Created by Lukas Schmidt on 20.10.16.
//  Copyright © 2016 DB Systel GmbH. All rights reserved.
//

import XCTest
import DBNetworkStackSourcing
import DBNetworkStack
import Sourcing

struct LocationCoordinate {
    let longitude: Double
    let latitude: Double
}

func testResource<T>(elements: [T]) -> Resource<Array<T>> {
    let url: URL! = URL(string: "bahn.de")
    let request = URLRequest(url: url)
    
    return Resource(request: request, parse: { _ in return elements })
}

class ResourceDataProviderTests: XCTestCase {
    var resourceDataProvider: ResourceDataProvider<LocationCoordinate>!
    var networkService: NetworkServiceMock!
    
    let location = LocationCoordinate(longitude: 0, latitude: 0)
    
    var didUpdateContents = false
    var notifiedDataSourceToProcess = false
    
    override func setUp() {
        super.setUp()
        
        networkService = NetworkServiceMock()
        
        resourceDataProvider = ResourceDataProvider(networkService: networkService, whenStateChanges: { _ in })
        resourceDataProvider.dataProviderDidUpdate = { [weak self] _ in
            self?.didUpdateContents = true
            self?.notifiedDataSourceToProcess = true
        }
        didUpdateContents = false
        notifiedDataSourceToProcess = false
        XCTAssert(resourceDataProvider.state.isEmpty)
    }
    
    func testInitEmpty() {
        
        //When
        let resourceDataProvider = ResourceDataProvider<Int>(networkService: networkService, whenStateChanges: { _ in })
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssertEqual(networkService.requestCount, 0)
    }
    
    func testInitWithResource() {
        //Given
        let resource = testResource(elements: [location])
        
        //When
        let resourceDataProvider = ResourceDataProvider(resource: resource, networkService: networkService, whenStateChanges: { _ in })
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssertEqual(networkService.requestCount, 0)
    }
    
    func testLoadResource() {
        //Given
        let resource = testResource(elements: [location])
        
        //When
        resourceDataProvider.reconfigure(with: resource)
        
        //Then
        XCTAssert(resourceDataProvider.state.isLoading)
        XCTAssertEqual(networkService.requestCount, 1)
    }
    
    func testClear() {
        //When
        resourceDataProvider.clear()
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssertEqual(networkService.requestCount, 0)
    }
    
    func testLoadResource_skipLoadingState() {
        //Given
        let resource = testResource(elements: [location])
        
        //When
        resourceDataProvider.reconfigure(with: resource, skipLoadingState: true)
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssertEqual(networkService.requestCount, 1)
    }
    
    func testLoadSucceed() {
        //Given
        let resource = testResource(elements: [location])
        
        //When
        resourceDataProvider.reconfigure(with: resource)
        networkService.returnSuccess()
        //Then
        XCTAssert(resourceDataProvider.state.hasSucceded)
        XCTAssertEqual(location.latitude, resourceDataProvider.contents.first?.first?.latitude)
        XCTAssert(notifiedDataSourceToProcess)
        XCTAssert(didUpdateContents)
    }
    
    func testLoadError() {
        //Given
        let resource = testResource(elements: [location])
        
        //When
        resourceDataProvider.reconfigure(with: resource)
        networkService.returnError(with: .unknownError)
        
        //Then
        XCTAssert(resourceDataProvider.state.hasError)
        XCTAssert(!didUpdateContents)
    }
    
    func testOnNetworkRequestCanceldWithEmptyData() {
        //Given
        let resource = testResource(elements: [location])
        
        //When
        resourceDataProvider.reconfigure(with: resource)
        networkService.returnError(with: .cancelled)
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssertEqual(networkService.requestCount, 1)
    }
    
    func testOnNetworkRequestCanceledWithNoEmptyData() {
        //Given
        resourceDataProvider = ResourceDataProvider(networkService: networkService, whenStateChanges: { _ in })
        let resource = testResource(elements: [location])
        
        //When
        resourceDataProvider.reconfigure(with: resource)
        networkService.returnError(with: .cancelled)
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssertEqual(networkService.requestCount, 1)
    }
}
