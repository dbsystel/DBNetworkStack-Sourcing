//
//  ResourceTest.swift
//
//  Copyright (C) 2016 DB Systel GmbH.
//	DB Systel GmbH; Jürgen-Ponto-Platz 1; D-60329 Frankfurt am Main; Germany; http://www.dbsystel.de/
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
//  Created by Lukas Schmidt on 01.09.16.
//

import Foundation
import XCTest
@testable import DBNetworkStack

class ResourceTest: XCTestCase {
    let request = NetworkRequest(path: "/trains", baseURLKey: "")
    
    static var allTests = {
        return [
            ("testResource", testResource),
            ("testResourceWithInvalidData", testResourceWithInvalidData),
            ("testCreateRessourceFromOtherRessource", testCreateRessourceFromOtherRessource)
        ]
    }()
    
    func testResource() {
        //Given
        let validData: Data! = "ICE".data(using: .utf8)

        let resource = Resource<String?>(request: request, parse: { String(data: $0, encoding: .utf8) })
        
        //When
        let name = try? resource.parse(validData)
        
        //Then
        XCTAssertEqual(name ?? nil, "ICE")
    }
    
    func testResourceWithInvalidData() {
        //Given
        let data = Data()
        let resource = JSONResource<Train>(request: request)
        
        //When
        do {
            _ = try resource.parse(data)
            XCTFail()
        } catch { }
    }
    
    func testCreateRessourceFromOtherRessource() {
        //Given
        let request = NetworkRequest(path: "/trains", baseURLKey: "")
        let arrayResource = JSONArrayResource<Train>(request: request)
        
        //When
        let ressource = arrayResource.wrapped()
        
        XCTAssert(ressource is Resource<Array<Train>>)
    }
}
