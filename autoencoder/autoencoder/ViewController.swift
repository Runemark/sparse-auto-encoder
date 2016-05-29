//
//  ViewController.swift
//  autoencoder
//
//  Created by Martin Mumford on 3/10/15.
//  Copyright (c) 2015 Runemark Studios. All rights reserved.
//
//  iOS image IO in swift based on this wonderful tutorial: http://www.raywenderlich.com/76285/beginning-core-image-swift
//  Extension to extract the RGBA values from a UIImage from this answer:

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Useful bits
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//        // This is how you perform a filter using CIImage
//        let filter = CIFilter(name: "GaussianBlur") // There is a wealth of filters you can apply as a pre-processing step
//        filter.setValue(beginImage, forKey:kCIInputImageKey)
//        filter.setValue(0.5, forKey:kCIInputIntensityKey)
//        let filteredImage = UIImage(CIImage:filter.outputImage)
/////////////////////////////////////////////////////////////////////////////////////////////////////////

import UIKit

class ViewController: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let windowSize = 4
        
        let dataset = datasetFromImagesNamed(["square1", "square2", "square3", "square4", "square5"], windowWidth:windowSize, windowHeight:windowSize)
      //  let dataset = datasetFromImagesNamed(["circle1", "circle2", "circle3"], windowWidth:windowSize, windowHeight:windowSize)
        let featureCount = dataset.features.colCount()
        let hiddenCount = featureCount/2
        let autoencoder = Autoencoder(featureCount:featureCount, hiddenCount:hiddenCount)
        
        for _ in 0...10
        {
            autoencoder.trainOnDataset(dataset)
        }
        
        
        var maximalWindows = [Array2D]()
        
        let docDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        
        for hiddenIndex in 0..<hiddenCount
        {
            let maximalInputVector = autoencoder.maximalInputVectorForHiddenNode(hiddenIndex)
            
            print(maximalInputVector)
            
            let maximalWindow = inputVectorToWindow(maximalInputVector, width:windowSize, height:windowSize)
            
            maximalWindows.append(maximalWindow)
        }
        
        for (index, maximalWindow): (Int, Array2D) in maximalWindows.enumerate()
        {
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(CGFloat(windowSize/2), CGFloat(windowSize/2)), true, 0.0)
            var newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
            
            for x in 0..<maximalWindow.rowCount()
            {
                for y in 0..<maximalWindow.colCount()
                {
                    let maximalValue = Int(floor(maximalWindow[x,y]*255))
                    newImage = newImage.setPixelColorAtPoint(CGPointMake(CGFloat(x), CGFloat(y)), color:(newRedColor:UInt8(0), newgreenColor:UInt8(0), newblueColor:UInt8(0),  newalphaValue:UInt8(maximalValue)))!
                }
            }
            
            let targetPath = docDirectory.stringByAppendingString("/derp\(index).png")
            UIImagePNGRepresentation(newImage)!.writeToFile(targetPath, atomically:true)
            UIGraphicsEndImageContext()
        }
        
        print("dir: \(docDirectory)")
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////
    // VISUALIZATION
    //////////////////////////////////////////////////////////////////////////////////////////
    func inputVectorToWindow(inputVector:[Float], width:Int, height:Int) -> Array2D
    {
        let window = Array2D(cols:width, rows:height)
        
        for x in 0..<height
        {
            for y in 0..<width
            {
                window[x,y] = inputVector[x*width+y]
            }
        }
        
        return window
    }
    
    func writeWindowToImage(window:Array2D, inout image:UIImage)
    {
        for x in 0..<window.rowCount()
        {
            for y in 0..<window.colCount()
            {
                let value8Bit = Int(floor(Double(window[x,y]*255)))
                image.setPixelAlphaAtPoint(CGPointMake(CGFloat(x),CGFloat(y)), alpha:UInt8(value8Bit))
            }
        }
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////
    // DATA EXTRACTION
    //////////////////////////////////////////////////////////////////////////////////////////
    
    func datasetFromImagesNamed(imageNames:[String], windowWidth:Int, windowHeight:Int) -> Dataset
    {
        let featureCount = windowWidth * windowHeight
        let outputCount = 1
        
        var totalInstances = 0
        var datasets = [Dataset]()
        for imageName in imageNames
        {
            let dataset = datasetFromImageNamed(imageName, windowWidth:windowWidth, windowHeight:windowHeight)
            datasets.append(dataset)
            totalInstances += dataset.instanceCount
        }
        
        let mergedDataset = Dataset(instances:totalInstances, featureCount:featureCount, outputCount:outputCount)
        
        for dataset in datasets
        {
            var globalInstance = 0
            
            for localInstance in 0..<dataset.instanceCount
            {
                let featureVector = dataset.getFeaturesForInstance(localInstance)
                for (n, feature): (Int, Float) in featureVector.enumerate()
                {
                    mergedDataset[0,globalInstance,n] = feature
                }
                globalInstance += 1
            }
            
            mergedDataset[1,globalInstance,0] = Float(0)
        }
        
        return mergedDataset
    }
    
    func datasetFromImageNamed(imageName:String, windowWidth:Int, windowHeight:Int) -> Dataset
    {
        let alphaValues = alphaValuesInImageFile(imageName)
        let chunks = slideWindowOverValues(alphaValues, windowWidth:windowWidth, windowHeight:windowHeight)
        
        let instanceCount = chunks.count
        let featureCount = windowWidth * windowHeight
        let outputCount = 1
        
        let dataset = Dataset(instances:instanceCount, featureCount:featureCount, outputCount:outputCount)
        
        for (i, value): (Int, Array2D) in chunks.enumerate()
        {
            let featureVector = value.toVector()
            
            for (n, floatValue): (Int, Float) in featureVector.enumerate()
            {
                dataset[0,i,n] = floatValue
            }
            
            dataset[1,i,0] = Float(0)
        }
        
        return dataset
    }
    
    func instancesFromImageNamed(imageName:String, windowWidth:Int, windowHeight:Int) -> [Instance]
    {
        let alphaValues = alphaValuesInImageFile(imageName)
        let chunks = slideWindowOverValues(alphaValues, windowWidth:windowWidth, windowHeight:windowHeight)
        
        var instances = [Instance]()
        for chunk in chunks
        {
            let featureVector = chunk.toVector()
            let instance = Instance(features:featureVector, outputs:[Float(0)])
            instances.append(instance)
        }
        
        return instances
    }
    
    func slideWindowOverValues(values:Array2D, windowWidth:Int, windowHeight:Int) -> [Array2D]
    {
        var chunks = [Array2D]()
        
        if windowWidth < values.colCount() && windowHeight < values.rowCount()
        {
            for x in 0...values.rowCount() - windowHeight
            {
                for y in 0...values.colCount() - windowWidth
                {
                    // Chunk identified, populate Array2D with values
                    let chunk = Array2D(cols:windowWidth, rows:windowHeight)
                    for chunk_x in 0..<windowHeight
                    {
                        for chunk_y in 0..<windowWidth
                        {
                            chunk[chunk_x, chunk_y] = values[x+chunk_x, y+chunk_y]
                        }
                    }
                    chunks.append(chunk)
                }
            }
        }
        
        return chunks
    }
    
    func alphaValuesInImageFile(fileName:String) -> Array2D
    {
        let fileURL = NSBundle.mainBundle().URLForResource(fileName, withExtension:"png")
        let beginImage = CIImage(contentsOfURL:fileURL!)
        
        let context = CIContext(options:nil)
        let cgimg:CGImage = context.createCGImage(beginImage!, fromRect:beginImage!.extent)
        let width = Int(beginImage!.extent.width)
        let height = Int(beginImage!.extent.height)
        let alphaValues = Array2D(cols:width, rows:height)
        
        
        let newImage = UIImage(CGImage: cgimg)
        if (newImage.CGImage != nil){
            for x in 0..<height
            {
                for y in 0..<width
                {
                    alphaValues[x,y] = Float(newImage.getPixelAlphaAtLocation(CGPointMake(CGFloat(x), CGFloat(y)))!)
                }
            }
        }
       

        return alphaValues
    }
    

}

