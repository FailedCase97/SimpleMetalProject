//
//  RenderingResources.swift
//  PhotoEditor
//
//  Created by Md. Rifat Haider Chowdhury on 24/8/22.
//

import UIKit
import GLKit

final class RenderingResources: NSObject {
    static let shared = RenderingResources()
    
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var defaultLibrary:MTLLibrary!
    
    var standardVertexBuffer: MTLBuffer!
    var standardTextureBuffer: MTLBuffer!
    
    var standardVertexFunction: MTLFunction!
    var standardTransformVertexFunction: MTLFunction!
    
    
    private var metalTextureCacheRef: CVMetalTextureCache!

    
    private override init() {
        super.init()
        initialize()
    }
    
    private func initialize() {
        self.device = MTLCreateSystemDefaultDevice()
        self.commandQueue = device.makeCommandQueue()
        self.defaultLibrary = device.makeDefaultLibrary()
        //TODO: - Rifat: for best practice release default library after creating all pipelines
        
    
        let vertexData:[Float] =
            [-1.0,-1.0,
             1.0,-1.0,
             -1.0,1.0,
             1.0,1.0]
        let textureData:[Float] =
            [0,1,
             1,1,
             0,0,
             1,0];
        
        let vertexDataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        self.standardVertexBuffer = device?.makeBuffer(bytes: vertexData, length: vertexDataSize, options: .storageModeShared)
        
        let textureDataSize = textureData.count * MemoryLayout.size(ofValue: textureData[0])
        self.standardTextureBuffer = device?.makeBuffer(bytes: textureData, length: textureDataSize, options: .storageModeShared)
        
        self.standardVertexFunction = self.defaultLibrary.makeFunction(name: "vertex_func")
        self.standardTransformVertexFunction = self.defaultLibrary.makeFunction(name: "vertex_func_transform")
        
        let status = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &metalTextureCacheRef)
        if status != noErr {
            print("Texture cache creation failed \(status)")
        }
    }

    func getTexture(from pixelBuffer: CVPixelBuffer?, textureCache: CVMetalTextureCache) -> MTLTexture? {
        guard let pixelBuffer = pixelBuffer else {
            return nil
        }

        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)

        var texture: CVMetalTexture?
        let status =
            CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil,
                                                      .bgra8Unorm, width, height, 0, &texture)
        if status == kCVReturnSuccess {
            guard let textureFromImage = texture else { return nil }

            guard let metalTexture = CVMetalTextureGetTexture(textureFromImage) else { return nil }
            return metalTexture
        } else { return nil }
    }
    
    public func getTexture(from image: UIImage?) -> MTLTexture? {
        
        guard let image = image else {return nil}
        var pixelBuffer: CVPixelBuffer?

        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue]

        var status = CVPixelBufferCreate(nil, Int(image.size.width), Int(image.size.height),
                                         kCVPixelFormatType_32BGRA, attrs as CFDictionary,
                                         &pixelBuffer)
        assert(status == noErr)

        let coreImage = CIImage(image: image)!
        let context = CIContext(mtlDevice: device)
        context.render(coreImage, to: pixelBuffer!)

        var textureWrapper: CVMetalTexture?

        status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                           metalTextureCacheRef, pixelBuffer!, nil, .bgra8Unorm,
                                                           CVPixelBufferGetWidth(pixelBuffer!), CVPixelBufferGetHeight(pixelBuffer!), 0, &textureWrapper)

        
        if status == kCVReturnSuccess {
            guard let textureFromImage = textureWrapper else { return nil }

            guard let metalTexture = CVMetalTextureGetTexture(textureFromImage) else { return nil }
            return metalTexture
        } else { return nil }
    }
    

    
    func makeThreadgroups(textureWidth: Int, textureHeight: Int) -> (threadgroupsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) {
        let threadSize = 16 // need to optimize
        let threadsPerThreadgroup = MTLSizeMake(threadSize, threadSize, 1)
        let horizontalThreadgroupCount = textureWidth / threadsPerThreadgroup.width + 1
        let verticalThreadgroupCount = textureHeight / threadsPerThreadgroup.height + 1
        let threadgroupsPerGrid = MTLSizeMake(horizontalThreadgroupCount, verticalThreadgroupCount, 1)
        
        return (threadgroupsPerGrid: threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
    }
    
    func getBuffer<T>(of variable: inout T) -> MTLBuffer?{
        let size = MemoryLayout.size(ofValue: variable)
        let buffer = self.device.makeBuffer(bytes: &variable, length: size, options: .storageModeShared)
        return buffer
    }
    func getBuffer<T>(of variable: inout [T]) -> MTLBuffer?{
        let size = MemoryLayout.size(ofValue: variable[0]) * variable.count
        let buffer = self.device.makeBuffer(bytes: &variable, length: size, options: .storageModeShared)
        return buffer
    }
    func getBuffer(of variable: inout GLKMatrix4) -> MTLBuffer?{
        let size = MemoryLayout.size(ofValue: variable)
        let buffer = self.device.makeBuffer(bytes: &variable.m, length: size, options: .storageModeShared)
        return buffer
    }
    
    
    func getTexture(of size: CGSize) -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .bgra8Unorm
        textureDescriptor.width = Int(size.width)
        textureDescriptor.height = Int(size.height)
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        let texture = device.makeTexture(descriptor: textureDescriptor)
        return texture!
    }
    
    
    
    func flushCommandQueue() {
        let commandBuffer = commandQueue.makeCommandBuffer()
        commandBuffer?.label = "Flush CommandBuffer"
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
    }
}

extension MTLTexture{
    
    func clearTexture(withColor color: [Float] = [0, 0, 0, 0], commandBuffer: MTLCommandBuffer? = nil){
        var cmdBuffer: MTLCommandBuffer! = commandBuffer
        if commandBuffer == nil{
            cmdBuffer = RenderingResources.shared.commandQueue.makeCommandBuffer()
        }
        cmdBuffer.label = "ClearColor CommandBuffer"
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = self
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: Double(color[0]), green: Double(color[1]), blue: Double(color[2]), alpha: Double(color[3]))
        let renderEncoder = cmdBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.endEncoding()
        
        if commandBuffer == nil{
            cmdBuffer.commit()
        }
        
        
    }
    
    func copy(to texture: MTLTexture, commandBuffer: MTLCommandBuffer? = nil) {
        var cmdBuffer: MTLCommandBuffer! = commandBuffer
        if commandBuffer == nil{
            cmdBuffer = RenderingResources.shared.commandQueue.makeCommandBuffer()
        }
        let blitEncoder = cmdBuffer.makeBlitCommandEncoder()
        blitEncoder?.copy(from: self, to: texture)
        blitEncoder?.endEncoding()
        if commandBuffer == nil{
            cmdBuffer.commit()
        }
    }
    
    func toImage(flushCommandQueue: Bool = true) -> UIImage {
        if flushCommandQueue == true{
            RenderingResources.shared.flushCommandQueue()
        }
        
        let w = self.width
        let h = self.height
        let bytesPerPixel: Int = 4
        let bytesPerRow = w * bytesPerPixel
        let src = malloc(w * h * 4)

        let region = MTLRegionMake2D(0, 0, w, h)
        self.getBytes(src!, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)

        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitsPerComponent = 8
        let context = CGContext(data: src!,
                                width: w,
                                height: h,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo)
        let cgImage = context?.makeImage()
        let image = UIImage(cgImage: cgImage!)
        src?.deallocate()
        return image
    }
}
