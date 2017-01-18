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
    var ressourceDataProvider: ResourceDataProvider<LocationCoordinate>!
    let networkService = FastNetworkService()
    
    let location = LocationCoordinate(longitude: 0, latitude: 0)
    
    var didUpdateContents = false
    
    override func setUp() {
        super.setUp()
        
        ressourceDataProvider = ResourceDataProvider(resource: nil, networkService: networkService, dataProviderDidUpdate: { [weak self] _ in
            self?.didUpdateContents = true
            }, whenStateChanges: { _ in
                
        })
        
        didUpdateContents = false
        XCTAssert(ressourceDataProvider.state.isEmpty)
    }
    
    func testGetPreloadedResources() {
        //When
        ressourceDataProvider = ResourceDataProvider(resource: nil, prefetchedData: [location],
                                                     networkService: networkService, dataProviderDidUpdate: { [weak self] _ in
            self?.didUpdateContents = true
            }, whenStateChanges: { _ in
                
        })
        
        //Then
        XCTAssert(ressourceDataProvider.state.hasSucceded)
        XCTAssertEqual(ressourceDataProvider.numberOfItems(inSection: 0), 1)
    }
    
    func testReplacePreloadedWithResources() {
        //Given
        let ressource = ListResourceMock(result: [location, location])
        
        //When
        ressourceDataProvider = ResourceDataProvider(resource: ressource, prefetchedData: [location],
                                                     networkService: networkService, dataProviderDidUpdate: { [weak self] _ in
                                                        self?.didUpdateContents = true
            }, whenStateChanges: { _ in
                
        })
        ressourceDataProvider.load()
        networkService.completeCurrentRequest?()
        
        //Then
        XCTAssert(ressourceDataProvider.state.hasSucceded)
        XCTAssertEqual(ressourceDataProvider.numberOfItems(inSection: 0), 2)
    }
    
    func testLoadResource() {
        //Given
        let ressource = ListResourceMock(result: [location])
        
        //When
        ressourceDataProvider.reconfigure(with: ressource)
        
        //Then
        XCTAssert(ressourceDataProvider.state.isLoading)
        XCTAssert(networkService.didRequestAResource)
    }
    
    func testLoadResource_skipLoadingState() {
        //Given
        let ressource = ListResourceMock(result: [location])
        
        //When
        ressourceDataProvider.reconfigure(with: ressource, clearBeforeLoading: false)
        
        //Then
        XCTAssert(ressourceDataProvider.state.isEmpty)
        XCTAssert(networkService.didRequestAResource)
    }
    
    func testLoadSucceed() {
        //Given
        let ressource = ListResourceMock(result: [location])
        
        //When
        ressourceDataProvider.reconfigure(with: ressource)
        networkService.completeCurrentRequest?()
        
        //Then
        XCTAssert(ressourceDataProvider.state.hasSucceded)
        XCTAssertEqual(location.latitude, ressourceDataProvider.data.first?.first?.latitude)
    }
    
    func testLoadEmpty() {
        //When
        ressourceDataProvider.reconfigure(with: nil)
        
        //Then
        XCTAssert(ressourceDataProvider.state.isEmpty)
        XCTAssert(didUpdateContents)
    }
    
    func testLoadError() {
        //Given
        let ressource = ListResourceMock(result: [location])
        
        //When
        ressourceDataProvider.reconfigure(with: ressource)
        networkService.errorCurrentRequest?(.unknownError)
        
        //Then
        XCTAssert(ressourceDataProvider.state.hasError)
        XCTAssert(!didUpdateContents)
    }
    
    func testSortedResult() {
        //Given
        let unsortedValues = [3, 1, 5]
        let ressource = ListResourceMock(result: unsortedValues)
        let dataProvider = ResourceDataProvider(resource: ressource, networkService: networkService,
                                                         dataProviderDidUpdate: { _ in }, whenStateChanges: { _ in })
        
        //When
        dataProvider.sortDescriptor = { $0 < $1 }
        dataProvider.load()
        networkService.completeCurrentRequest?()
        
        //Then
        let firstObject = dataProvider.object(at: IndexPath(item: 0, section: 0))
        XCTAssertEqual(firstObject, 1)
    }

}
