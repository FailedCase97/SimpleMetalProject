//
//  EditingViewController.swift
//  OpenGL - 1
//
//  Created by Rifat on 21/6/20.
//  Copyright © 2020 Rifat. All rights reserved.
//

import UIKit

class EditingViewController: UIViewController {
    
    @IBOutlet weak var opacitySlider: UISlider!
    
    var image: UIImage!

    @IBOutlet weak var canvasView: CanvasContainerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        canvasView.image = image
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        print("SLIDER:: \(sender.value)")
        self.canvasView.update(sender.value)
    }
    

}
