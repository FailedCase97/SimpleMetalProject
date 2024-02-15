//
//  BasicDrawer.swift
//  PhotoEditor
//
//  Created by Md. Rifat Haider Chowdhury on 24/8/22.
//
import Metal
import MetalKit

class BasicDrawer: NSObject {
    
    private static let vertexFunctionName = "basicDrawerVertex"
    private static let fragmentFunctionName = "basicDrawerFragment"
    private static let pipelineState: MTLRenderPipelineState? = BasicDrawer.generatePipelineState()
    
    
    override init() {
        super.init()
    }
    
    private static func generatePipelineState() -> MTLRenderPipelineState? {
        let vertex_func = RenderingResources.shared.defaultLibrary.makeFunction(name: self.vertexFunctionName)
        let fragment_func = RenderingResources.shared.defaultLibrary.makeFunction(name: self.fragmentFunctionName)
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex_func
        descriptor.fragmentFunction = fragment_func
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        do {
            let pipelineState = try RenderingResources.shared.device.makeRenderPipelineState(descriptor: descriptor)
            return pipelineState
        } catch let error {
            print("Pipeline State Creation Error: \(error)")
        }
        return nil
    }
    
    
    func draw(imageTexture: MTLTexture,
              imageTexture2: MTLTexture,
              on textureFrameBuffer: MTLTexture,
              drawable: CAMetalDrawable?,
              opacity: Float = 1.0,
              vertexData: [Float] = [],
              textureData: [Float] = [],
              commandBuffer: MTLCommandBuffer? = nil
    ){
        
        var vertexData = vertexData
        var textureData = textureData

        guard let pipelineState = BasicDrawer.pipelineState else {
            return
        }
        
        var cmdBuffer: MTLCommandBuffer! = commandBuffer
        
        if commandBuffer == nil{
            cmdBuffer = RenderingResources.shared.commandQueue.makeCommandBuffer()
        }
        
        
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = textureFrameBuffer
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        
        let renderEncoder = cmdBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        if vertexData.count > 0  {
            let vertexBuffer = RenderingResources.shared.getBuffer(of: &vertexData)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        } else {
            renderEncoder.setVertexBuffer(RenderingResources.shared.standardVertexBuffer, offset: 0, index: 0)
        }
        
        if textureData.count > 0 {
            let textureBuffer = RenderingResources.shared.getBuffer(of: &textureData)
            renderEncoder.setVertexBuffer(textureBuffer, offset: 0, index: 1)
        } else {
            renderEncoder.setVertexBuffer(RenderingResources.shared.standardTextureBuffer, offset: 0, index: 1)
        }
        


        renderEncoder.setFragmentTexture(imageTexture, index: 0)
        renderEncoder.setFragmentTexture(imageTexture2, index: 1)

        var opacity = opacity
        let opacityBuffer = RenderingResources.shared.getBuffer(of: &opacity)
        renderEncoder.setFragmentBuffer(opacityBuffer, offset: 0, index: 0)

        
        
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        if let drawable = drawable {
            cmdBuffer?.present(drawable)
        }
        
        
        if commandBuffer == nil{
            cmdBuffer.commit()
        }
        
        
        
    }
    
}

    
