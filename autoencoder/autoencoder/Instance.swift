//
//  Instance.swift
//  autoencoder
//
//  Created by Martin Mumford on 3/10/15.
//  Copyright (c) 2015 Runemark Studios. All rights reserved.
//

import Foundation

class Instance
{
    var features = [Float]()
    var outputs = [Float]()
    
    init(features:[Float], outputs:[Float])
    {
        self.features = features
        self.outputs = outputs
    }
}