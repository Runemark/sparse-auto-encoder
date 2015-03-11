//
//  Array2D.swift
//  autoencoder
//
//  Created by Martin Mumford on 3/10/15.
//  Copyright (c) 2015 Runemark Studios. All rights reserved.
//
//  Modified from http://blog.trolieb.com/trouble-multidimensional-arrays-swift/

import Foundation

class Array2D : NSObject
{
    var cols:Int, rows:Int
    var matrix:[Float]
    
    override var description : String {
        
        var description = "cols = \(cols)\nrows = \(rows)\n"
        for x in 0..<rows
        {
            description += "[\(x)]"
            for y in 0..<cols
            {
                description += " \(y):\(matrix[cols * x + y])"
            }
            description += "\n"
        }
        
        return description
//        return "**** PageContentViewController\npageIndex equals ****\n"
    }
    
    init(cols:Int, rows:Int) {
        self.cols = cols
        self.rows = rows
        matrix = Array(count:cols*rows, repeatedValue:0)
    }
    
    subscript(col:Int, row:Int) -> Float {
        get {
            return matrix[cols * row + col]
        }
        set {
            matrix[cols*row+col] = newValue
        }
    }
    
    func toVector() -> [Float]
    {
        return matrix
    }
    
    func colCount() -> Int {
        return self.cols
    }
    
    func rowCount() -> Int {
        return self.rows
    }
}
