//
//  GLCanvasView.swift
//  OpenGL - 1
//
//  Created by Rifat on 21/6/20.
//  Copyright © 2020 Rifat. All rights reserved.
//

import UIKit

class RenderingCanvas: UIView {
    
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
    
    
    
    var image: UIImage!
    
    
    private var drawingLayer: CAMetalLayer!
    private var isInitialized: Bool = false
    var opacity: Float = 0.0 {
        didSet {
            self.renderProject()
        }
    }
    override class var layerClass: AnyClass{
        return CAMetalLayer.self
    }
    
    private var resources: RenderingResources = RenderingResources.shared
    
    //textures
    private var imageTexture: MTLTexture!
    private var imageTexture2: MTLTexture!

    //drawers
    private var basicDrawer: BasicDrawer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureDrawingLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.isInitialized == false{
            self.isInitialized = true
            self.initializedVariables()
            self.renderProject()
        }
    }
    
    private func configureDrawingLayer(){
        self.drawingLayer = layer as? CAMetalLayer
        self.drawingLayer.device = RenderingResources.shared.device
        self.drawingLayer.pixelFormat = .bgra8Unorm
        self.drawingLayer.framebufferOnly = true
        self.drawingLayer.frame = self.layer.bounds
        self.drawingLayer.isOpaque = false
        self.drawingLayer.borderColor = UIColor.green.cgColor
        self.drawingLayer.borderWidth = 5
    }
    
    private func initializedVariables(){
//        self.image = UIImage(named: "cat")
        self.imageTexture = resources.getTexture(from: self.image)
//        self.imageTexture = resources.getTexture(from: UIImage(named: "cat"))
//        self.imageTexture2 = resources.getTexture(from: UIImage(named: "dog"))

//        self.imageTexture = resources.getTexture(from: UIImage(named: "landscape"))
        self.imageTexture2 = resources.getTexture(from: UIImage(named: "portrait"))
        self.basicDrawer = BasicDrawer()
    }
    
    func renderProject(){
        if let drawable = self.getDrawable(){
            let commandBuffer = resources.commandQueue.makeCommandBuffer()
            let vertexData1 = self.getVertexData()
            print(vertexData1)
            self.basicDrawer.draw(imageTexture: self.imageTexture, imageTexture2: self.imageTexture2, on: drawable.texture, drawable: drawable, opacity: opacity, vertexData: vertexData1, textureData: textureData, commandBuffer: commandBuffer)
            commandBuffer?.commit()
        }
        
    }

    private func getVertexData() -> [Float] {
        var vertexData1: [Float] = [-1.0,-1.0,
                            1.0,-1.0,
                            -1.0,1.0,
                            1.0,1.0]
        let imgWidth = self.image.size.width
        let imgHeight = self.image.size.height
        print("IMAGE:: height:: \(imgHeight) ---  width:: \(imgWidth)")

        if imgWidth != imgHeight {
            var halfWidth = imgWidth
            var halfHeight = imgHeight
            while halfWidth > 1 || halfHeight > 1 {
                halfWidth /= 10
                halfHeight /= 10
            }

            if halfWidth > halfHeight {
                halfHeight *= (1/halfWidth)
                halfWidth = 1
            } else if halfWidth < halfHeight {
                halfWidth *= (1/halfHeight)
                halfHeight = 1
            }

            var val = halfHeight
            vertexData1[1] = -1.0 * Float(val)
            vertexData1[3] = -1.0 * Float(val)
            vertexData1[5] = Float(val)
            vertexData1[7] = Float(val)
            val = halfWidth
            vertexData1[0] = -1.0 * Float(val)
            vertexData1[2] = Float(val)
            vertexData1[4] = -1.0 * Float(val)
            vertexData1[6] = Float(val)
        }

        return vertexData1
    }

    func getDrawable() -> CAMetalDrawable?{
        if self.isInitialized == false{return nil}
        return self.drawingLayer.nextDrawable()
    }
}
