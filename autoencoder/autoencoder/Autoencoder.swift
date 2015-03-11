//
//  Autoencoder.swift
//  autoencoder
//
//  Created by Martin Mumford on 3/10/15.
//  Copyright (c) 2015 Runemark Studios. All rights reserved.
//

import Foundation

enum Layer
{
    case Input, Hidden, Output
}

class Autoencoder
{
    // Weights
    var firstWeights:Array2D
    var secondWeights:Array2D
    
    var inputActivations:[Float]
    var hiddenActivations:[Float]
    var outputActivations:[Float]
    
    var outputDeltas:[Float]
    var hiddenDeltas:[Float]
    
    var featureCount:Int
    var hiddenCount:Int
    
    // features (f), hidden (h)
    init(featureCount:Int, hiddenCount:Int)
    {
        self.featureCount = featureCount
        self.hiddenCount = hiddenCount
        
        // h*(f+1)
        self.firstWeights = Array2D(cols:hiddenCount, rows:featureCount+1)
        self.secondWeights = Array2D(cols:featureCount, rows:hiddenCount+1)
        
        self.inputActivations = Array<Float>(count:featureCount+1, repeatedValue:0)
        self.hiddenActivations = Array<Float>(count:hiddenCount+1, repeatedValue:0)
        self.outputActivations = Array<Float>(count:featureCount, repeatedValue:0)
        
        self.outputDeltas = Array<Float>(count:featureCount, repeatedValue:0)
        self.hiddenDeltas = Array<Float>(count:hiddenCount, repeatedValue:0)
        
        initializeWeights()
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////
    // Training
    //////////////////////////////////////////////////////////////////////////////////////////
    
    func trainOnDataset(dataset:Dataset)
    {
        let firstInstance = (features:dataset.getFeaturesForInstance(0), outputs:dataset.getOutputsForInstance(0))
        trainOnInstance(firstInstance)
    }
    
    func trainOnInstance(instance:(features:[Float],outputs:[Float]))
    {
        calculateCostForInstance(instance.features)
    }
    
    
    //////////////////////////////////////////////////////////////////////////////////////////
    // Weights
    //////////////////////////////////////////////////////////////////////////////////////////
    
    func smallRandomNumber() -> Float
    {
        return ((Float(arc4random()) / Float(UINT32_MAX)) * 0.02) - 0.01
    }
    
    func getWeight(fromLayer:Layer, fromIndex:Int, toIndex:Int) -> Float
    {
        if (fromLayer == .Input)
        {
            return firstWeights[fromIndex,toIndex]
        }
        else
        {
            return secondWeights[fromIndex,toIndex]
        }
    }
    
    func setWeight(fromLayer:Layer, fromIndex:Int, toIndex:Int, value:Float)
    {
        if (fromLayer == .Input)
        {
            firstWeights[fromIndex,toIndex] = value
        }
        else
        {
            secondWeights[fromIndex,toIndex] = value
        }
    }
    
    func initializeWeights()
    {
        for x in 0..<firstWeights.rowCount()
        {
            for y in 0..<firstWeights.colCount()
            {
                firstWeights[x,y] = smallRandomNumber()
            }
        }
        
        for x in 0..<secondWeights.rowCount()
        {
            for y in 0..<secondWeights.colCount()
            {
                secondWeights[x,y] = smallRandomNumber()
            }
        }
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////
    // Feedforward
    //////////////////////////////////////////////////////////////////////////////////////////
    
    func initializeInputAndBiasActivations(featureVector:[Float])
    {
        // Initialize input activations
        
        for featureIndex in 0..<featureCount
        {
            inputActivations[featureIndex] = featureVector[featureIndex]
        }
        
        // Initialize bias activations
        
        inputActivations[featureCount] = 1
        hiddenActivations[hiddenCount] = 1
    }
    
    func getActivation(layer:Layer, index:Int) -> Float
    {
        if (layer == .Input)
        {
            return inputActivations[index]
        }
        else if (layer == .Hidden)
        {
            return hiddenActivations[index]
        }
        else
        {
            return outputActivations[index]
        }
    }
    
    func calculateCostForInstance(featureVector:[Float])
    {
        calculateActivationsForInstance(featureVector)
    }
    
    func calculateActivationsForInstance(featureVector:[Float])
    {
        initializeInputAndBiasActivations(featureVector)
        
        for hiddenIndex in 0..<hiddenCount
        {
            hiddenActivations[hiddenIndex] = calculateActivation(.Hidden, index:hiddenIndex)
        }
        
        for outputIndex in 0..<featureCount
        {
            outputActivations[outputIndex] = calculateActivation(.Output, index:outputIndex)
        }
    }
    
    func calculateActivation(layer:Layer, index:Int) -> Float
    {
        if (layer == .Hidden)
        {
            // This will include the bias as well
            var net:Float = 0
            for inputIndex in 0...featureCount
            {
                let weight = getWeight(.Input, fromIndex:inputIndex, toIndex:index)
                net += weight*inputActivations[inputIndex]
            }
            
            return sigmoid(net)
        }
        else
        {
            var net:Float = 0
            for hiddenIndex in 0...hiddenCount
            {
                let weight = getWeight(.Hidden, fromIndex:hiddenIndex, toIndex:index)
                net += weight*hiddenActivations[hiddenIndex]
            }
            
            return sigmoid(net)
        }
    }
    
    func sigmoid(value:Float) -> Float
    {
        return Float(Double(1.0) / (Double(1.0) + pow(M_E, -1 * Double(value))))
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////
    // Backprop
    //////////////////////////////////////////////////////////////////////////////////////////
    
    func calculateDeltas()
    {
        for outputIndex in 0..<featureCount
        {
            outputDeltas[outputIndex] = calculateDelta(.Output, index:outputIndex)
        }
        
        for hiddenIndex in 0..<hiddenCount
        {
            hiddenDeltas[hiddenIndex] = calculateDelta(.Hidden, index:hiddenIndex)
        }
    }
    
    func calculateDelta(layer:Layer, index:Int) -> Float
    {
        if (layer == .Output)
        {
            let target = getActivation(.Input, index:index)
            let actual = getActivation(.Output, index:index)
            
            return -1 * (target - actual) * sigmoidDerivative(actual)
        }
        else
        {
            var weightedSum:Float = 0
            for j in 0..<featureCount
            {
                weightedSum += getWeight(.Hidden, fromIndex:index, toIndex:j) * outputDeltas[j]
            }
            
            let activation = getActivation(.Hidden, index:index)
            return weightedSum * sigmoidDerivative(activation)
        }
    }
    
    func sumAllWeights() -> Float
    {
        var sum:Float = 0
        
        let firstLayerWeights = firstWeights.toVector()
        let secondLayerWeights = secondWeights.toVector()
        
        for weightIndex in 0..<firstLayerWeights.count
        {
            sum += firstLayerWeights[weightIndex]
        }
        
        for weightIndex in 0..<secondLayerWeights.count
        {
            sum += secondLayerWeights[weightIndex]
        }
        
        return sum
    }
    
    func sigmoidDerivative(value:Float) -> Float
    {
        return value * (1 - value)
    }
}
