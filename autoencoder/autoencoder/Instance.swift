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
    var features = [Double]()
    var outputs = [Double]()
    
    init(features:[Double], outputs:[Double])
    {
        self.features = features
        self.outputs = outputs
    }
}