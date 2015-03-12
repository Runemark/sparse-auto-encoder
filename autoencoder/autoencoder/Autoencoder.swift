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
    
    var learningRate:Float = 1
    
    // features (f), hidden (h)
    init(featureCount:Int, hiddenCount:Int)
    {
        self.featureCount = featureCount
        self.hiddenCount = hiddenCount
        
        self.firstWeights = Array2D(cols:hiddenCount, rows:featureCount+1)
        self.secondWeights = Array2D(cols:featureCount, rows:hiddenCount+1)
        
        self.inputActivations = Array<Float>(count:featureCount+1, repeatedValue:0)
        self.hiddenActivations = Array<Float>(count:hiddenCount+1, repeatedValue:0)
        self.outputActivations = Array<Float>(count:featureCount, repeatedValue:0)
        
        self.outputDeltas = Array<Float>(count:featureCount, repeatedValue:0)
        self.hiddenDeltas = Array<Float>(count:hiddenCount, repeatedValue:0)
        
        let spaceComplexity = 3*featureCount + 2*hiddenCount + 2*(featureCount*hiddenCount)
        println("space complexity: \(spaceComplexity)")
        
        initializeWeights()
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////
    // Visualization
    //////////////////////////////////////////////////////////////////////////////////////////
    
    // what input x would cause the hidden nodes to be maximally activated?
    
    // for each hidden node
    // for each input i
        // xi (max input unit i) = Wij / sqrt( sum (weight^2) )
    
    func maximalInputVectorForHiddenNode(nodeIndex:Int) -> [Float]
    {
        var maximalInputVector = Array<Float>(count:featureCount, repeatedValue:0)
        
        for inputIndex in 0..<featureCount
        {
            maximalInputVector[inputIndex] = maximalInputForHiddenNode(nodeIndex, inputIndex:inputIndex)
        }
        
        return maximalInputVector
    }
    
    func maximalInputForHiddenNode(nodeIndex:Int, inputIndex:Int) -> Float
    {
        let weight = getWeight(.Input, fromIndex:inputIndex, toIndex:nodeIndex)
        
        var sumSquaredWeight:Float = 0
        for i in 0..<featureCount
        {
            let inputWeight = getWeight(.Input, fromIndex:i, toIndex:nodeIndex)
            let squaredInputWeight = Float(pow(Double(inputWeight), 2))
            sumSquaredWeight += squaredInputWeight
        }
        
        return weight / Float(sqrt(Double(sumSquaredWeight)))
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////
    // Training
    //////////////////////////////////////////////////////////////////////////////////////////
    
    func trainOnDataset(dataset:Dataset)
    {
        for m in 0..<dataset.instanceCount
        {
            // standard autoencoding: the features and targets are identical
            // vs. de-noising: the features are slightly mutated
            let instance = (features:dataset.getFeaturesForInstance(m), targets:dataset.getFeaturesForInstance(m))
            println("training on instance \(m) of \(dataset.instanceCount)")
            trainOnInstance(instance)
        }
    }
    
    func trainOnInstance(instance:(features:[Float],targets:[Float]))
    {
        calculateActivationsForInstance(instance.features)
        calculateDeltas(instance.targets)
        applyWeightDeltas()
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
        // WARXING: FINISH
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
    
    func applyWeightDeltas()
    {
        // calculate firstWeights delta values (between input and hidden layers)
        for fromWeightIndex in 0...featureCount
        {
            for toWeightIndex in 0..<hiddenCount
            {
                let oldWeightValue = firstWeights[fromWeightIndex,toWeightIndex]
                let weightDelta = calculateWeightDelta(.Input, fromIndex:fromWeightIndex, toIndex:toWeightIndex)
                firstWeights[fromWeightIndex,toWeightIndex] = oldWeightValue + weightDelta
            }
        }
        
        // calculate secondWeights delta values (between hidden and output layers)
        for fromWeightIndex in 0...hiddenCount
        {
            for toWeightIndex in 0..<featureCount
            {
                let oldWeightValue = secondWeights[fromWeightIndex,toWeightIndex]
                let weightDelta = calculateWeightDelta(.Hidden, fromIndex:fromWeightIndex, toIndex:toWeightIndex)
                secondWeights[fromWeightIndex,toWeightIndex] = oldWeightValue + weightDelta
            }
        }
    }
    
    func calculateWeightDelta(fromLayer:Layer, fromIndex:Int, toIndex:Int) -> Float
    {
        var nextLayer:Layer = .Output
        if (fromLayer == .Input)
        {
            nextLayer = .Hidden
        }
        
        return learningRate * getActivation(fromLayer, index:fromIndex) * getDelta(nextLayer, index:toIndex)
    }
    
    func calculateDeltas(outputVector:[Float])
    {
        for outputIndex in 0..<featureCount
        {
            outputDeltas[outputIndex] = calculateOutputDelta(outputIndex, target:outputVector[outputIndex])
        }
        
        for hiddenIndex in 0..<hiddenCount
        {
            hiddenDeltas[hiddenIndex] = calculateHiddenDelta(hiddenIndex)
        }
    }
    
    func calculateOutputDelta(index:Int, target:Float) -> Float
    {
        let actual = getActivation(.Output, index:index)
        return -1 * (target - actual) * sigmoidDerivative(actual)
    }
    
    func calculateHiddenDelta(index:Int) -> Float
    {
        var weightedSum:Float = 0
        for j in 0..<featureCount
        {
            weightedSum += getWeight(.Hidden, fromIndex:index, toIndex:j) * outputDeltas[j]
        }
        
        let activation = getActivation(.Hidden, index:index)
        return weightedSum * sigmoidDerivative(activation)
    }
    
    func getDelta(layer:Layer, index:Int) -> Float
    {
        if (layer == .Output)
        {
            return outputDeltas[index]
        }
        else
        {
            return hiddenDeltas[index]
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
