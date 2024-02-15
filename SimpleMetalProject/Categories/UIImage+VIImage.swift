//
//  UIImage+VIImage.swift
//  OpenGL - 1
//
//  Created by Rifat on 21/6/20.
//  Copyright © 2020 Rifat. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    @objc public func resizeImage(newSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let targteImage = renderer.image { _ in
            self.draw(in: CGRect.init(origin: CGPoint.zero, size: newSize))
        }
        return targteImage
    }
    
    @objc public func getTargetSize(targetSize: CGSize) -> CGSize {
        var convertSize = self.size
        if convertSize.width > targetSize.width {
            convertSize.height = (convertSize.height / convertSize.width) * targetSize.width
            convertSize.width = targetSize.width
        }
        
        if(convertSize.height > targetSize.height) {
            convertSize.width = (convertSize.width / convertSize.height) * targetSize.height
            convertSize.height = targetSize.height
        }
        return convertSize
    }
    
    @objc public func cropImageToRect(cropRect: CGRect) -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        var rect = cropRect
        rect.origin.x *= self.scale
        rect.origin.y *= self.scale
        rect.size.width *= self.scale
        rect.size.height *= self.scale
        guard rect.size.width>0.0 && rect.size.height>0.0 else {
            return nil
        }
        let imageRef = cgImage.cropping(to: rect)
        let image = UIImage(cgImage: imageRef!, scale: self.scale, orientation: self.imageOrientation)
        return image
    }
}

import Accelerate
extension UIImage{
    @objc public func resizeImageUsingVImage(size:CGSize) -> UIImage? {
        let cgImage = self.cgImage!
        var format = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 32, colorSpace: nil, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue), version: 0, decode: nil, renderingIntent: CGColorRenderingIntent.defaultIntent)
        var sourceBuffer = vImage_Buffer()
        defer {
            free(sourceBuffer.data)
        }
        var error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, numericCast(kvImageNoFlags))
        guard error == kvImageNoError else { return nil }
        // create a destination buffer
        let scale = self.scale
        let destWidth = Int(size.width)
        let destHeight = Int(size.height)
        let bytesPerPixel = self.cgImage!.bitsPerPixel/8
        let destBytesPerRow = destWidth * bytesPerPixel
        let destData = UnsafeMutablePointer<UInt8>.allocate(capacity: destHeight * destBytesPerRow)
        defer {
//            destData.deallocate(capacity: destHeight * destBytesPerRow)  // Previous
            destData.deallocate()                                          // Current
        }
        var destBuffer = vImage_Buffer(data: destData, height: vImagePixelCount(destHeight), width: vImagePixelCount(destWidth), rowBytes: destBytesPerRow)
        // scale the image
        error = vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, numericCast(kvImageHighQualityResampling))
        guard error == kvImageNoError else { return nil }
        // create a CGImage from vImage_Buffer
        var destCGImage = vImageCreateCGImageFromBuffer(&destBuffer, &format, nil, nil, numericCast(kvImageNoFlags), &error)?.takeRetainedValue()
        guard error == kvImageNoError else { return nil }
        // create a UIImage
        let resizedImage = destCGImage.flatMap { UIImage(cgImage: $0, scale: 0.0, orientation: self.imageOrientation) }
        destCGImage = nil
        return resizedImage
    }
}


