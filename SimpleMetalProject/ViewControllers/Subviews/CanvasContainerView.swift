//
//  CanvasView.swift
//  OpenGL - 1
//
//  Created by Rifat on 21/6/20.
//  Copyright © 2020 Rifat. All rights reserved.
//

import UIKit

class CanvasContainerView: UIView {
    private static let canvasSize: CGSize = CGSize(width: 2048, height: 2048)

    var image: UIImage?
    
    private var scrollView: UIScrollView?
    private var containerView: UIView?
    private var metalCanvasView: RenderingCanvas?
    private var isUIInitialized = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !self.isUIInitialized {
            self.isUIInitialized = true
            self.initialize()
        }
        self.setZoomParametersForSize(scrollView!.bounds.size)
        self.recenterScrollViewContent()
    }
    
    private func initialize(){
        scrollView = UIScrollView(frame: bounds)
        scrollView?.showsVerticalScrollIndicator = false
        scrollView?.showsHorizontalScrollIndicator = false
        scrollView?.delegate = self
        addSubview(scrollView!)
        
//        containerView = UIView(frame: CGRect(origin: .zero, size: image!.size))
        containerView = UIView(frame: CGRect(origin: .zero, size: CanvasContainerView.canvasSize))
        scrollView?.addSubview(containerView!)
        
//        metalCanvasView = RenderingCanvas(frame: CGRect(origin: .zero, size: image!.size))
        metalCanvasView = RenderingCanvas(frame: CGRect(origin: .zero, size: CanvasContainerView.canvasSize))
        metalCanvasView?.image = image
        containerView?.addSubview(metalCanvasView!)
        scrollView?.panGestureRecognizer.isEnabled = false
        
        
    }

}

extension CanvasContainerView: UIScrollViewDelegate{
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.recenterScrollViewContent()
    }
    private func recenterScrollViewContent() {
        let imageContainerSize = containerView!.frame.size
        
        
        let actualWidth: CGFloat = imageContainerSize.width
        let left = 0.5 * (actualWidth > scrollView!.bounds.width ? 0: (scrollView!.bounds.width - actualWidth))
        
        let actualHeight: CGFloat = imageContainerSize.height
        let top = 0.5 * (actualHeight > scrollView!.bounds.height ? 0: (scrollView!.bounds.height - actualHeight))
        
        self.scrollView!.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
    
    }
    private func setZoomParametersForSize(_ scrollViewSize: CGSize) {
        let imageSize = CanvasContainerView.canvasSize
        let widthScale = scrollViewSize.width / imageSize.width
        let heightScale = scrollViewSize.height / imageSize.height
        
        let minScale = min(widthScale, heightScale)
        
        scrollView!.minimumZoomScale = minScale
        scrollView!.maximumZoomScale = 6.0
        scrollView!.zoomScale = minScale
    }

    func update(_ opacity: Float) {
        self.metalCanvasView?.opacity = opacity
    }
}
