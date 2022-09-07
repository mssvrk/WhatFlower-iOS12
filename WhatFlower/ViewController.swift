//
//  ViewController.swift
//  WhatFlower
//
//  Created by Mac on 02/09/2022.
//  Copyright © 2022 Sviridova Maria. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var discriptionLabel: UILabel!
    
    
    let imagePicker = UIImagePickerController()
    var pickedImage : UIImage?
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        
    }

    @IBAction func cameraButtonPressed(_ sender: UIBarButtonItem) {

        pickPhoto()
    }
    
    //MARK:- Image Helper Methods
    
    func choosePhotoFromLibrary() {
        
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    func takePhotoWithCamera() {
        
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    func showPhotoMenu() {
        let alert = UIAlertController(title: nil, message: nil,
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: {
            action in
            self.takePhotoWithCamera()
        }))
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: {
            action in
            self.choosePhotoFromLibrary()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)

    }
    
    func pickPhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showPhotoMenu()
        } else {
            choosePhotoFromLibrary()
        }
        
    }
    
    // MARK:- ImagePicker Delegate Methods:
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Can not convert image to CIImage")
            }
            detect(flowerImage: ciImage)
            
//        imageView.image = userPickedImage
 
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    //MARK:- CoreML Model Methods:
    
    func detect(flowerImage: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Can not import model")
        }
        let request = VNCoreMLRequest(model: model) {
            (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify image.")
            }

            self.navigationItem.title = classification.identifier.capitalized
            self.requestFlowerInfo(flowerName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: flowerImage)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    //MARK:- Networking:
    
    func requestFlowerInfo(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        

        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON {
            (response) in
            if response.result.isSuccess {
                print("Got the Wikipedia info!")
                print(response.result.value!)
                
                let flowerJSON : JSON = JSON(response.result.value!)
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDiscription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                
                self.discriptionLabel.text = flowerDiscription
            }

        }
        
    }
    
}

