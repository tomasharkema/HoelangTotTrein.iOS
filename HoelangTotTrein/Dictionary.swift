//
//  Dictionary.swift
//  HoelangTotTrein
//
//  Created by Tomas Harkema on 15-02-15.
//  Copyright (c) 2015 Tomas Harkema. All rights reserved.
//

import Foundation

extension Dictionary {
    func mapKeys<U> (transform: Key -> U) -> Array<U> {
        var results: Array<U> = []
        for k in self.keys {
            results.append(transform(k))
        }
        return results
    }
    
    func mapValues<U> (transform: Value -> U) -> Array<U> {
        var results: Array<U> = []
        for v in self.values {
            results.append(transform(v))
        }
        return results
    }
    
    func map<U> (transform: Value -> U) -> Array<U> {
        return self.mapValues(transform)
    }
    
    func map<U> (transform: (Key, Value) -> U) -> Array<U> {
        var results: Array<U> = []
        for k in self.keys {
            results.append(transform(k as Key, self[ k ]! as Value))
        }
        return results
    }
    
    func map<K: Hashable, V> (transform: (Key, Value) -> (K, V)) -> Dictionary<K, V> {
        var results: Dictionary<K, V> = [:]
        for k in self.keys {
            if let value = self[ k ] {
                let (u, w) = transform(k, value)
                results.updateValue(w, forKey: u)
            }
        }
        return results
    }
}
