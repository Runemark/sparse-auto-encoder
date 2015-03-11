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
        
        let dataset = datasetFromImageNamed("square1", windowWidth:8, windowHeight:8)
        let featureCount = dataset.features.colCount()
        let hiddenCount = featureCount/2
        let autoencoder = Autoencoder(featureCount:featureCount, hiddenCount:hiddenCount)
        autoencoder.trainOnDataset(dataset)
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    //////////////////////////////////////////////////////////////////////////////////////////
    // DATA EXTRACTION
    //////////////////////////////////////////////////////////////////////////////////////////
    
    func datasetFromImageNamed(imageName:String, windowWidth:Int, windowHeight:Int) -> Dataset
    {
        let alphaValues = alphaValuesInImageFile(imageName)
        let chunks = slideWindowOverValues(alphaValues, windowWidth:windowWidth, windowHeight:windowHeight)
        
        let instanceCount = chunks.count
        let featureCount = windowWidth * windowHeight
        let outputCount = 1
        
        var dataset = Dataset(instances:instanceCount, featureCount:featureCount, outputCount:outputCount)
        
        for (i:Int, value:Array2D) in enumerate(chunks)
        {
            let featureVector = value.toVector()
            
            for (n:Int, floatValue:Float) in enumerate(featureVector)
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
        
        if windowWidth < values.colCount()  && windowHeight < values.rowCount()
        {
            for x in 0...values.rowCount() - windowHeight
            {
                for y in 0...values.colCount() - windowWidth
                {
                    // Chunk identified, populate Array2D with values
                    var chunk = Array2D(cols:windowWidth, rows:windowHeight)
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
        let beginImage = CIImage(contentsOfURL:fileURL)
        
        let context = CIContext(options:nil)
        let cgimg = context.createCGImage(beginImage, fromRect:beginImage.extent())
        let width = Int(beginImage.extent().width)
        let height = Int(beginImage.extent().height)
        
        var alphaValues = Array2D(cols:width, rows:height)
        
        if let newImage = UIImage(CGImage:cgimg)
        {
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

