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
        
        resourceDataProvider = ResourceDataProvider(resource: nil, networkService: networkService, whenStateChanges: { _ in })
        resourceDataProvider.dataProviderDidUpdate = { [weak self] _ in
            self?.didUpdateContents = true
            self?.notifiedDataSourceToProcess = true
        }
        didUpdateContents = false
        notifiedDataSourceToProcess = false
        XCTAssert(resourceDataProvider.state.isEmpty)
    }
    
    func testGetPreloadedResources() {
        //When
        resourceDataProvider = ResourceDataProvider(resource: nil, prefetchedData: [location],
                                                     networkService: networkService, whenStateChanges: { _ in })
        
        //Then
        XCTAssert(resourceDataProvider.state.hasSucceded)
        XCTAssertEqual(resourceDataProvider.numberOfItems(inSection: 0), 1)
    }
    
    func testInitEmpty() {
        //Given
        let resource: Resource<Array<LocationCoordinate>>? = nil
        
        //When
        let resourceDataProvider = ResourceDataProvider(resource: resource,
                                                     networkService: networkService, whenStateChanges: { _ in })
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssertEqual(networkService.requestCount, 0)
    }
    
    func testReplacePreloadedWithResources() {
        //Given
        let resource = testResource(elements: [location, location])
        
        //When
        resourceDataProvider = ResourceDataProvider(resource: resource, prefetchedData: [location],
                                                     networkService: networkService, whenStateChanges: { _ in })
        resourceDataProvider.dataProviderDidUpdate = { [weak self] _ in
            self?.didUpdateContents = true
        }
        resourceDataProvider.load()
        networkService.returnSuccess()
        
        //Then
        XCTAssert(resourceDataProvider.state.hasSucceded)
        XCTAssertEqual(resourceDataProvider.numberOfItems(inSection: 0), 2)
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
    
    func testLoadResourceNil() {
        //Given
        let resource: Resource<Array<LocationCoordinate>>? = nil
        //When
        resourceDataProvider.reconfigure(with: resource)
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssertEqual(networkService.requestCount, 0)
    }
    
    func testLoadResource_skipLoadingState() {
        //Given
        let resource = testResource(elements: [location])
        
        //When
        resourceDataProvider.reconfigure(with: resource, clearBeforeLoading: false)
        
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
    
    func testLoadEmpty() {
        //When
        resourceDataProvider.reconfigure(with: nil)
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssert(didUpdateContents)
        XCTAssert(notifiedDataSourceToProcess)
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
    
    func testSortedResult() {
        //Given
        let unsortedValues = [3, 1, 5]
        let resource = testResource(elements:  unsortedValues)
        let dataProvider = ResourceDataProvider(resource: resource,
                                                networkService: networkService, whenStateChanges: { _ in })
        
        //When
        dataProvider.sortDescriptor = { $0 < $1 }
        dataProvider.load()
        networkService.returnSuccess()
        
        //Then
        let firstObject = dataProvider.object(at: IndexPath(item: 0, section: 0))
        XCTAssertEqual(firstObject, 1)
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
    
    func testOnNetworkRequestCanceldWithNoEmptyData() {
        //Given
        resourceDataProvider = ResourceDataProvider(resource: nil, prefetchedData: [location],
                                                    networkService: networkService, whenStateChanges: { _ in })
        let resource = testResource(elements: [location])
        
        //When
        resourceDataProvider.reconfigure(with: resource)
        networkService.returnError(with: .cancelled)
        
        //Then
        XCTAssert(resourceDataProvider.state.hasSucceded)
        XCTAssertEqual(networkService.requestCount, 1)
    }
}
