//
//  ViewController.swift
//  NeuralStyleTransfer
//
//  Created by Xiaoyu Wang on 3/12/20.
//  Copyright © 2020 Xiaoyu Wang. All rights reserved.
//

import UIKit
import Toast_Swift

class ViewController: UIViewController {
    typealias FilteringCompletion = ((UIImage?, Error?) -> ())
    
    // style selector view on the bottom
    @IBOutlet weak var CollectionView: UICollectionView!
    
    // show the image on the main view
    @IBOutlet private var imageView: UIImageView!
    
    // the loader when applying the style for image
    @IBOutlet private var loader: UIActivityIndicatorView!
    
    // selected model
    var selectedModel: AllModel = .pointllism
    
    // select image from the file system
    var imagePicker = UIImagePickerController()
    
    // take an image by camera
    var cameraPicker = UIImagePickerController()

    // init default image
    var selectedImage = UIImage(named: "chicago")
    
    // items for styles
    var items = ["Original", "Pointillism", "Starry Night", "Scream", "Muse", "Udnie", "Candy"]
    
    // if the style is applying, if true, show the loader, else hide the loader
    var isProcessing : Bool = false {
        didSet {
            self.isProcessing ? self.loader.startAnimating() : self.loader.stopAnimating()
            if(self.isProcessing){
                loader.startAnimating()
            }else{
                loader.stopAnimating()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
       
    /*
     do init actions
     **/
    override func viewWillAppear(_ animated: Bool) {
        self.isProcessing = false
    }
    
    /*
     do process : coreml
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
            print("Select an image first!")
            return
        }
        self.isProcessing = true
        self.process(input: image) { filteredImage, error in
            self.isProcessing = false
            // show the pop view on the bottom
            self.showPopView()
            if let filteredImage = filteredImage {
                self.imageView.image = filteredImage
            } else if let error = error {
                print(error)
            } else {
                print(ErrorUtil.unknown)
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
            cell.imageView.image = #imageLiteral(resourceName: "pointillism")
        case 2:
            cell.lbl.text = items[2]
            cell.imageView.image = #imageLiteral(resourceName: "starrynight")
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

    /*
     for UICollectionViewDelegate
     **/
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.imageView.image = self.selectedImage
        if(indexPath.item == 0){
            return;
        }
        self.selectedModel = AllModel.allCases[indexPath.item - 1]
        applyStyle()
    }
    
    /*
     show popview on the bottom when the process of applying style was finished
     **/
    func showPopView(){
        let alert = UIAlertController(title: "action", message: "please choose one action", preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: "Cancel", style:.default, handler: nil)
        let save = UIAlertAction(title: "Save", style: .default, handler: {
            ACTION in
            self.saveImage()
        })
        let share = UIAlertAction(title: "Share", style: .default, handler: {
            ACTION in
            self.shareSocialMedia()
        })
        alert.addAction(save)
        alert.addAction(share)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    /*
     save image action
     **/
    func saveImage(){
        let image = self.imageView.image!
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        self.view.makeToast("Save Image Success!", duration: 3.0, position: .center)
    }
    
    /*
     share to the social media action
     **/
    func shareSocialMedia(){
        // save image first when you share the image
        saveImage()
        
        // share function
        let activityVC = UIActivityViewController(activityItems: [self.imageView.image!, "Share Image"], applicationActivities: nil)
        activityVC.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            if error != nil {
                self.view.makeToast("Error:\(error!.localizedDescription)")
                return
            }
            if completed {
                self.view.makeToast("Share Successful!")
            }
        }
        self.present(activityVC, animated: true, completion: nil)
    }
    
}
