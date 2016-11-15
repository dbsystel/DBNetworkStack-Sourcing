//
//  DataProviderListResource.swift
//  BFACore
//
//	Legal Notice! DB Systel GmbH proprietary License!
//
//	Copyright (C) 2015 DB Systel GmbH
//	DB Systel GmbH; Jürgen-Ponto-Platz 1; D-60329 Frankfurt am Main; Germany; http://www.dbsystel.de/

//	This code is protected by copyright law and is the exclusive property of
//	DB Systel GmbH; Jürgen-Ponto-Platz 1; D-60329 Frankfurt am Main; Germany; http://www.dbsystel.de/

//	Consent to use ("licence") shall be granted solely on the basis of a
//	written licence agreement signed by the customer and DB Systel GmbH. Any
//	other use, in particular copying, redistribution, publication or
//	modification of this code without written permission of DB Systel GmbH is
//	expressly prohibited.

//	In the event of any permitted copying, redistribution or publication of
//	this code, no changes in or deletion of author attribution, trademark
//	legend or copyright notice shall be made.
//
//  Created by Lukas Schmidt on 20.10.16.
//

import Foundation
import DBNetworkStack


public extension ResourceModeling {
    func toListResource<Element>(mapToList: @escaping (Self.Model) -> Array<Element>) -> DataProviderListResource<Element, Self.Model, Self> {
        return DataProviderListResource(resource: self, map: mapToList)
    }
}

public struct DataProviderListResource<_Element, SourceType, Resource: ResourceModeling>: ArrayResourceModeling where Resource.Model == SourceType {
    public typealias Element = _Element
    public typealias Model = Array<Element>
    let resource: Resource
    let map: (SourceType) -> DataProviderListResource.Model
    
    public init(resource: Resource, map: @escaping (SourceType) -> DataProviderListResource.Model) {
        self.resource = resource
        self.map = map
    }
    
    public var parse: (_ data: Data) throws -> Array<Element> {
        return parseMap
    }
    
    public var request: NetworkRequestRepresening {
        return resource.request
    }
    
    private func parseMap(data: Data) throws -> DataProviderListResource.Model {
        return map(try resource.parse(data))
    }
}
