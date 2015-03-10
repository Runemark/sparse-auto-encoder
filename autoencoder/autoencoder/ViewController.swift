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

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let fileURL = NSBundle.mainBundle().URLForResource("square1", withExtension:"png")
        let beginImage = CIImage(contentsOfURL:fileURL)
        
        let context = CIContext(options:nil)
        let cgimg = context.createCGImage(beginImage, fromRect:beginImage.extent())
        let width = Int(beginImage.extent().width)
        let height = Int(beginImage.extent().height)
        
        var alphaValues = [[CGFloat]]()
        
        if let newImage = UIImage(CGImage:cgimg)
        {
            for y in 0..<width
            {
                var alphaValueRow = [CGFloat]()
                for x in 0..<height
                {
                    alphaValueRow.append(newImage.getPixelAlphaAtLocation(CGPointMake(CGFloat(x), CGFloat(y)))!)
                }
                alphaValues.append(alphaValueRow)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

