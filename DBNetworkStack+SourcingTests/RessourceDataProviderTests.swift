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

class ResourceDataProviderTests: XCTestCase {
    var resourceDataProvider: ResourceDataProvider<LocationCoordinate>!
    let networkService = FastNetworkService()
    
    let location = LocationCoordinate(longitude: 0, latitude: 0)
    
    var didUpdateContents = false
    var notifiedDataSourceToProcess = false
    
    override func setUp() {
        super.setUp()
        
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
        let resource: ListResourceMock<LocationCoordinate>? = nil
        
        //When
        let resourceDataProvider = ResourceDataProvider(resource: resource,
                                                     networkService: networkService, whenStateChanges: { _ in })
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssert(!networkService.didRequestAResource)
    }
    
    func testReplacePreloadedWithResources() {
        //Given
        let resource = ListResourceMock(result: [location, location])
        
        //When
        resourceDataProvider = ResourceDataProvider(resource: resource, prefetchedData: [location],
                                                     networkService: networkService, whenStateChanges: { _ in })
        resourceDataProvider.dataProviderDidUpdate = { [weak self] _ in
            self?.didUpdateContents = true
        }
        resourceDataProvider.load()
        networkService.completeCurrentRequest?()
        
        //Then
        XCTAssert(resourceDataProvider.state.hasSucceded)
        XCTAssertEqual(resourceDataProvider.numberOfItems(inSection: 0), 2)
    }
    
    func testLoadResource() {
        //Given
        let resource = ListResourceMock(result: [location])
        
        //When
        resourceDataProvider.reconfigure(with: resource)
        
        //Then
        XCTAssert(resourceDataProvider.state.isLoading)
        XCTAssert(networkService.didRequestAResource)
    }
    
    func testLoadResourceNil() {
        //Given
        let resource: ListResourceMock<LocationCoordinate>? = nil
        //When
        resourceDataProvider.reconfigure(with: resource)
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssert(!networkService.didRequestAResource)
    }
    
    func testLoadResource_skipLoadingState() {
        //Given
        let resource = ListResourceMock(result: [location])
        
        //When
        resourceDataProvider.reconfigure(with: resource, clearBeforeLoading: false)
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssert(networkService.didRequestAResource)
    }
    
    func testLoadSucceed() {
        //Given
        let resource = ListResourceMock(result: [location])
        
        //When
        resourceDataProvider.reconfigure(with: resource)
        networkService.completeCurrentRequest?()
        
        //Then
        XCTAssert(resourceDataProvider.state.hasSucceded)
        XCTAssertEqual(location.latitude, resourceDataProvider.data.first?.first?.latitude)
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
        let resource = ListResourceMock(result: [location])
        
        //When
        resourceDataProvider.reconfigure(with: resource)
        networkService.errorCurrentRequest?(.unknownError)
        
        //Then
        XCTAssert(resourceDataProvider.state.hasError)
        XCTAssert(!didUpdateContents)
    }
    
    func testSortedResult() {
        //Given
        let unsortedValues = [3, 1, 5]
        let resource = ListResourceMock(result: unsortedValues)
        let dataProvider = ResourceDataProvider(resource: resource,
                                                networkService: networkService, whenStateChanges: { _ in })
        
        //When
        dataProvider.sortDescriptor = { $0 < $1 }
        dataProvider.load()
        networkService.completeCurrentRequest?()
        
        //Then
        let firstObject = dataProvider.object(at: IndexPath(item: 0, section: 0))
        XCTAssertEqual(firstObject, 1)
    }
    
    func testOnNetworkRequestCanceldWithEmptyData() {
        //Given
        let resource = ListResourceMock(result: [location])
        
        //When
        resourceDataProvider.reconfigure(with: resource)
        networkService.errorCurrentRequest?(.cancelled)
        
        //Then
        XCTAssert(resourceDataProvider.state.isEmpty)
        XCTAssert(networkService.didRequestAResource)
    }
    
    func testOnNetworkRequestCanceldWithNoEmptyData() {
        //Given
        resourceDataProvider = ResourceDataProvider(resource: nil, prefetchedData: [location],
                                                    networkService: networkService, whenStateChanges: { _ in })
        let resource = ListResourceMock(result: [location])
        
        //When
        resourceDataProvider.reconfigure(with: resource)
        networkService.errorCurrentRequest?(.cancelled)
        
        //Then
        XCTAssert(resourceDataProvider.state.hasSucceded)
        XCTAssert(networkService.didRequestAResource)
    }
}
