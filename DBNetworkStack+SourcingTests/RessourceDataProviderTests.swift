//
//  ResourceDataProviderTests.swift
//  BFACore
//
//  Created by Lukas Schmidt on 20.10.16.
//  Copyright © 2016 DB Systel GmbH. All rights reserved.
//

import XCTest
@testable import DBNetworkStackSourcing
import DBNetworkStack

struct LocationCoordinate {
    let longitude: Double
    let latitude: Double
}

class FastNetworkService: NetworkServiceProviding {
    fileprivate var completeCurrentRequest: (() -> ())?
    fileprivate var errorCurrentRequest: ((DBNetworkStackError) -> ())?
    var didRequestAResource: Bool { return completeCurrentRequest != nil }
    func request<T : ResourceModeling>(_ ressource: T, onCompletion: @escaping (T.Model) -> (), onError: @escaping (DBNetworkStackError) -> ()) -> NetworkTaskRepresenting {
        completeCurrentRequest = {
            onCompletion(try! ressource.parse(Data()))
        }
        
        errorCurrentRequest = { error in
            onError(error)
        }
        
        return NetworkTaskMock()
    }
}

struct MockListResource<Element_>: ArrayResourceModeling {
    typealias Element = Element_
    let result: Array<Element>
    var parse: (_ data: Data) throws -> Array<Element> {
        return test
    }
    
    func test(data: Data) -> Array<Element> {
        return result
    }
    
    var request: NetworkRequestRepresening {
        return NetworkRequest(path: "", baseURLKey: "")
    }
}

class ResourceDataProviderTests: XCTestCase {
    var ressourceDataProvider: ResourceDataProvider<LocationCoordinate>!
    let networkService = FastNetworkService()
    
    var didUpdateContents = false
    
    override func setUp() {
        super.setUp()
        
        ressourceDataProvider = ResourceDataProvider(ressource: nil, networkService: networkService, dataProviderDidUpdate: { [weak self] updates in
            self?.didUpdateContents = true
            }, whenStateChanges: { state in
                
        })
        
        didUpdateContents = false
        XCTAssertEqual(ressourceDataProvider.state, ResourceDataProviderState.empty)
    }
    
    func testLoadResource() {
        //Given
        let location = LocationCoordinate(longitude: 0, latitude: 0)
        let ressource = MockListResource(result: [location])
        
        //When
        ressourceDataProvider.reconfigure(ressource)
        
        //Then
        XCTAssert(ressourceDataProvider.state == .loading)
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
        XCTAssert(ressourceDataProvider.state == .success)
        XCTAssertEqual(location.latitude, ressourceDataProvider.data.first?.first?.latitude)
    }
    
    func testLoadEmpty() {
        //Given
        
        //When
        ressourceDataProvider.reconfigure(nil)
        
        //Then
        XCTAssert(ressourceDataProvider.state == .empty)
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
        XCTAssert(ressourceDataProvider.state == .error)
        XCTAssert(!didUpdateContents)
    }
    
    
}
