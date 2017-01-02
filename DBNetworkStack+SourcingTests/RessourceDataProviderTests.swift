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

struct LocationCoordinate {
    let longitude: Double
    let latitude: Double
}

class ResourceDataProviderTests: XCTestCase {
    var ressourceDataProvider: ResourceDataProvider<LocationCoordinate>!
    let networkService = FastNetworkService()
    
    var didUpdateContents = false
    
    override func setUp() {
        super.setUp()
        
        ressourceDataProvider = ResourceDataProvider(resource: nil, networkService: networkService, dataProviderDidUpdate: { [weak self] updates in
            self?.didUpdateContents = true
            }, whenStateChanges: { state in
                
        })
        
        didUpdateContents = false
        XCTAssert(ressourceDataProvider.state.isEmpty)
    }
    
    func testLoadResource() {
        //Given
        let location = LocationCoordinate(longitude: 0, latitude: 0)
        let ressource = MockListResource(result: [location])
        
        //When
        ressourceDataProvider.reconfigure(ressource)
        
        //Then
        XCTAssert(ressourceDataProvider.state.isLoading)
        XCTAssert(networkService.didRequestAResource)
    }
    
    func testLoadSucceed() {
        ()
        //Given
        let location = LocationCoordinate(longitude: 0, latitude: 0)
        let ressource = MockListResource(result: [location])
        
        //When
        ressourceDataProvider.reconfigure(ressource)
        networkService.completeCurrentRequest?()
        
        //Then
        XCTAssert(ressourceDataProvider.state.hasSucceded)
        XCTAssertEqual(location.latitude, ressourceDataProvider.data.first?.first?.latitude)
    }
    
    func testLoadEmpty() {
        //Given
        
        //When
        ressourceDataProvider.reconfigure(nil)
        
        //Then
        XCTAssert(ressourceDataProvider.state.isEmpty)
        XCTAssert(didUpdateContents)
    }
    
    func testLoadError() {
        //Given
        let location = LocationCoordinate(longitude: 0, latitude: 0)
        let ressource = MockListResource(result: [location])
        
        //When
        ressourceDataProvider.reconfigure(ressource)
        networkService.errorCurrentRequest?(.unknownError)
        
        //Then
        XCTAssert(ressourceDataProvider.state.hasError)
        XCTAssert(!didUpdateContents)
    }
    
    
}
