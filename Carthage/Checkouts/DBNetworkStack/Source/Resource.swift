//
//  Resource.swift
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
//  Created by Lukas Schmidt on 21.07.16.
//

import Foundation

/**
 `Resource` describes a remote resource of generic type.
 The type can be fetched via HTTP(s) and parsed into the coresponding model object.
 */
public struct Resource<Model>: ResourceModeling {
    public let request: NetworkRequestRepresening
    public let parse: (_ data: Data) throws -> Model
    
    public init(request: NetworkRequestRepresening, parse: @escaping (Data) throws -> Model) {
        self.request = request
        self.parse = parse
    }
}

public extension ResourceModeling {
    
    /// Wrappes self into a `Resource` to hide away implementation details. This could be helpful when you think your typeinformation gets leaked.
    ///
    /// - Returns: the wrapped ressource
    func wrapped() -> Resource<Model> {
        return Resource(request: request, parse: parse)
    }
}