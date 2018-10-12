//
//  Copyright (C) DB Systel GmbH.
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

import DBNetworkStack

/// Represents the state of a resource data provider
public enum ResourceDataProviderState {
    /// When loading a resource succeeds. Even if the result is empty, the state is `.sucess` and not `.empty`.
    case success
    /// When an error occurs. The associated value represents the error
    case error(NetworkError)
    /// When loading happens. The associated value is the loading task
    case loading(NetworkTask)
    /// When the data provider has not yet loaded anything.
    case empty
}

extension ResourceDataProviderState {
    /// When loading happens.
    public var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    /// When an error occurs.
    public var hasError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
    
    /// When loading a resource succeeds. Even if the result is empty, the state is `.sucess` and not `.empty`.
    public var hasSucceded: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    /// When the data provider has not yet loaded anything.
    public var isEmpty: Bool {
        if case .empty = self {
            return true
        }
        return false
    }
}
