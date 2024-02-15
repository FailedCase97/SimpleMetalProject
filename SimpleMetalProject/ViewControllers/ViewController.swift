//
//  ViewController.swift
//  SimpleMetalProject
//
//  Created by Md. Rifat Haider Chowdhury on 3/11/22.
//

import UIKit

class ViewController: UIViewController {
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func pickerPressed(_ sender: UIButton) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        present(pickerController, animated: true, completion: nil)
    }

}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let editingViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "EditingViewController") as! EditingViewController
        
        var img = info[.originalImage] as! UIImage
        
        if let resizedImage = img.resizeImageUsingVImage(size: img.getTargetSize(targetSize: CGSize(width: 2048, height: 2048))){
            img = resizedImage
        }
        
        editingViewController.image = img
        picker.dismiss(animated: true, completion: nil)
        
        navigationController?.pushViewController(editingViewController, animated: true)
    }
}

