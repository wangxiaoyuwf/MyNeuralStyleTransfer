//
//  ViewController.swift
//  NeuralStyleTransfer
//
//  Created by Xiaoyu Wang on 3/12/20.
//  Copyright © 2020 Xiaoyu Wang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    typealias FilteringCompletion = ((UIImage?, Error?) -> ())
    
    @IBOutlet weak var CollectionView: UICollectionView!
    @IBOutlet private var segmentedControl: UISegmentedControl!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var loader: UIActivityIndicatorView!
    @IBOutlet private var applyButton: UIButton!
    
    //xiaoyu: selected model
    var selectedModel: AllModel = .princess

    var imagePicker = UIImagePickerController()

    var cameraPicker = UIImagePickerController()

    //xiaoyu: init default image
    var selectedImage = UIImage(named: "chicago")
    
    var isProcessing : Bool = false {
        didSet {
//            self.applyButton.isEnabled = !isProcessing
            self.isProcessing ? self.loader.startAnimating() : self.loader.stopAnimating()
            // xiaoyu: show/hide with the loader icon
            if(self.isProcessing){
                loader.startAnimating()
            }else{
                loader.stopAnimating()
            }
            
//            UIView.animate(withDuration: 0.3) {
//                self.isProcessing
//                    ? self.applyButton.setTitle("Processing...", for: .normal)
//                    : self.applyButton.setTitle("Apply Style", for: .normal)
//                self.view.layoutIfNeeded()
//            }
        }
    }
    
    var items = ["Original", "Rain Princess", "Wave", "Scream", "Muse", "Udnie", "Candy"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
       
    override func viewWillAppear(_ animated: Bool) {
        //xiaoyu: do init
        self.isProcessing = false
//        CollectionView.delegate = self
//        CollectionView.dataSource = self
    }
    
    /*
     xiaoyu: show error
     **/
    func showError(_ error: Error) {
        self.applyButton.setTitle(error.localizedDescription, for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.applyButton.setTitle("Apply Style", for: .normal)
        }
    }
        
    /*
     xiaoyu: do process, CoreML
     **/
    func process(input: UIImage, completion: @escaping FilteringCompletion) {
        var outputImage: UIImage?
        var errorUtil: Error?
        let startTime = CFAbsoluteTimeGetCurrent()
        
        //xiaoyu: using asynchronously because prediction may take a few seconds
        DispatchQueue.global().async {
            
            //xiaoyu: Load model and prediction
            do {
                let modelProvider = try self.selectedModel.modelProvider()
                outputImage = try modelProvider.prediction(inputImage: input)
            } catch let error {
                errorUtil = error
            }
            
            //xiaoyu: give result to main thread
            DispatchQueue.main.async {
                if let outputImage = outputImage {
                    completion(outputImage, nil)
                } else if let errorUtil = errorUtil{
                    completion(nil, errorUtil)
                } else {
                    completion(nil, ErrorUtil.unknown)
                }
                let endTime = CFAbsoluteTimeGetCurrent()
                let timeSpend = endTime - startTime
                print("Time we take for applying: \(timeSpend) s.")
            }
        }
    }
        
    /*
     xiaoyu: import image from file system
     **/
    @IBAction func importFromFileSystem() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            self.imagePicker.delegate = self
            self.imagePicker.sourceType = .photoLibrary
            self.imagePicker.allowsEditing = false
            self.present(self.imagePicker, animated: true)
        }else {
            print("Photo Library not available")
        }
    }
        
    /*
     xiaoyu: get image from camera
     **/
    @IBAction func camera(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            self.cameraPicker.delegate = self
            self.cameraPicker.sourceType = .camera
            self.cameraPicker.allowsEditing = true
            self.present(self.cameraPicker, animated: true)
        } else {
            print("Camera not available")
        }
        
    }
    
    /*
     xiaoyu: apply action
     **/
    func applyStyle() {
        guard let image = self.imageView.image else {
            print("Select an image first")
            return
        }

        self.isProcessing = true
        self.process(input: image) { filteredImage, error in
            self.isProcessing = false
            if let filteredImage = filteredImage {
                self.imageView.image = filteredImage
            } else if let error = error {
                self.showError(error)
            } else {
                self.showError(ErrorUtil.unknown)
            }
        }
    }
}

/*
 xiaoyu: Image Picker UI Controller
 **/
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.selectedImage = pickedImage
            self.imageView.image = pickedImage
            self.imageView.backgroundColor = .clear
        }
        self.dismiss(animated: true)
    }
}

/*
 xiaoyu: CollectionView
 **/
extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    // for UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }

    // for each cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("collectionview...")
        let cell:StyleCollectionViewCell =
            collectionView.dequeueReusableCell(withReuseIdentifier: "filter", for: indexPath)
            as! StyleCollectionViewCell
        switch indexPath.item {
        case 0:
            cell.lbl.text = items[0]
            cell.imageView.image = #imageLiteral(resourceName: "chicago")
        case 1:
            cell.lbl.text = items[1]
            cell.imageView.image = #imageLiteral(resourceName: "rainprincess")
        case 2:
            cell.lbl.text = items[2]
            cell.imageView.image = #imageLiteral(resourceName: "wave")
        case 3:
            cell.lbl.text = items[3]
            cell.imageView.image = #imageLiteral(resourceName: "screamImg")
        case 4:
            cell.lbl.text = items[4]
            cell.imageView.image = #imageLiteral(resourceName: "museImg")
        case 5:
            cell.lbl.text = items[5]
            cell.imageView.image = #imageLiteral(resourceName: "Udanie")
        case 6:
            cell.lbl.text = items[6]
            cell.imageView.image = #imageLiteral(resourceName: "candy")
        default:
            cell.lbl.text = ""
        }

        return cell
    }

    // for UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.imageView.image = self.selectedImage
        if(indexPath.item == 0){
            return;
        }
        self.selectedModel = AllModel.allCases[indexPath.item - 1]
        applyStyle()
    }
}
