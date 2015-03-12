//
//  Dataset.swift
//  autoencoder
//
//  Created by Martin Mumford on 3/10/15.
//  Copyright (c) 2015 Runemark Studios. All rights reserved.
//

import Foundation

class Dataset
{
    var features:Array2D
    var outputs:Array2D
    var instanceCount:Int
    
    init(instances:Int, featureCount:Int, outputCount:Int)
    {
        self.instanceCount = instances
        self.features = Array2D(cols:featureCount, rows:instances)
        self.outputs = Array2D(cols:outputCount, rows:instances)
    }
    
    subscript(io:Int, instance:Int, index:Int) -> Float
    {
        get
        {
            if (io == 0)
            {
                return features[instance, index]
            }
            else
            {
                return outputs[instance, index]
            }
        }
        set {
            
            if (io == 0)
            {
                features[instance, index] = newValue
            }
            else
            {
                outputs[instance, index] = newValue
            }
        }
    }
    
    func getFeaturesForInstance(index:Int) -> [Float]
    {
        return features.getRow(index)
    }
    
    func getOutputsForInstance(index:Int) -> [Float]
    {
        return outputs.getRow(index)
    }
}
