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
    public var completeCurrentRequest: (() -> ())?
    public var errorCurrentRequest: ((DBNetworkStackError) -> ())?
    var didRequestAResource: Bool { return completeCurrentRequest != nil }
    func request<T : ResourceModeling>(_ resource: T, onCompletion: @escaping (T.Model) -> (), onError: @escaping (DBNetworkStackError) -> ()) -> NetworkTask {
        completeCurrentRequest = {
            onCompletion(try! resource.parse(Data()))
        }
        
        errorCurrentRequest = { error in
            onError(error)
        }
        
        return NetworkTaskMock()
    }
}

struct MockListResource<Element_>: ArrayResourceModeling {
    typealias Element = Element_
    typealias Model = Array<Element>
    let result: Array<Element>
    public var parse: (_ data: Data) throws -> Model {
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
    var resourceDataProvider: ResourceDataProvider<MockListResource<LocationCoordinate>>!
    let networkService = FastNetworkService()
    
    var didUpdateContents = false
    
    override func setUp() {
        super.setUp()
        resourceDataProvider = ResourceDataProvider(resource: nil, networkService: networkService, dataProviderDidUpdate: { [weak self] updates in
            self?.didUpdateContents = true
        })
        didUpdateContents = false
        XCTAssertEqual(resourceDataProvider.state, ResourceDataProviderState.Empty)
    }
    
    func testLoadResource() {
        //Given
        let location = LocationCoordinate(longitude: 0, latitude: 0)
        let resource = MockListResource(result: [location])
        
        //When
        resourceDataProvider.reconfigureData(resource: resource)
        
        //Then
        XCTAssert(resourceDataProvider.state == .Loading)
        XCTAssert(networkService.didRequestAResource)
    }
    
    func testLoadSucceed() {
        //Given
        let location = LocationCoordinate(longitude: 0, latitude: 0)
        let resource = MockListResource(result: [location])
        
        //When
        resourceDataProvider.reconfigureData(resource: resource)
        networkService.completeCurrentRequest?()
        
        //Then
        XCTAssert(resourceDataProvider.state == .Success)
        XCTAssertEqual(location.latitude, resourceDataProvider.data.first?.first?.latitude)
    }
    
    func testLoadEmpty() {
        //Given
        
        //When
        resourceDataProvider.reconfigureData(resource: nil)
        
        //Then
        XCTAssert(resourceDataProvider.state == .Empty)
        XCTAssert(didUpdateContents)
    }
    
    func testLoadError() {
        //Given
        let location = LocationCoordinate(longitude: 0, latitude: 0)
        let resource = MockListResource(result: [location])
        
        //When
        resourceDataProvider.reconfigureData(resource: resource)
        networkService.errorCurrentRequest?(.unknownError)
        
        //Then
        XCTAssert(resourceDataProvider.state == .Error)
        XCTAssert(!didUpdateContents)
    }
    
    
}
