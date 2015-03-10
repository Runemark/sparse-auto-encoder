//
//  main.swift
//  autoencoder
//
//  Created by Martin Mumford on 3/10/15.
//  Copyright (c) 2015 Runemark Studios. All rights reserved.
//

import Foundation

// Stage 0: Generate a dataset by using a sliding window of many images (8x8)

// In swift, we use a CIImage object. We can later extend this to initialize using our custom files for 3D voxels, rather than just standard image formats.

let fileURL = NSBundle.mainBundle().URLForResource("image", withExtension:"png")



