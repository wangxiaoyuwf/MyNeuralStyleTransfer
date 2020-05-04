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
    var items = [NSLocalizedString("original", comment: ""), NSLocalizedString("pointillism", comment: ""), NSLocalizedString("starry_night", comment: ""), NSLocalizedString("scream", comment: ""), NSLocalizedString("muse", comment: ""), NSLocalizedString("udnie", comment: ""), NSLocalizedString("candy", comment: ""), NSLocalizedString("wave", comment: "")]
    
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
    
    // download model function: url
    var urlCandyModelCloud = "https://192.168.1.78:3011/public/models/FNS-Candy.mlmodel"
    
    // download model function: session
    private var session: URLSession? = nil
    
    // download model function: response data
    private var responseData: Data? = nil
    
    // create a DownloadUtil instance
    var downloadUtil: DownloadUtil = DownloadUtil()
    
    // candy download status
    var candyDownloadStatus: Int = 0
        
    // download model
    var downloadModel:String = "FNS-Candy"
    
    // ViewController
    var collectionView: UICollectionView? = nil
    
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
        
        // using asynchronously because prediction may take a few seconds
        DispatchQueue.global().async {
            // Load model and prediction
            do {
                let modelProvider = try self.selectedModel.modelProvider()
                outputImage = try modelProvider.prediction(inputImage: input)
            } catch let error {
                errorUtil = error
            }
            
            // give the result to main thread
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
     import image from file system
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
     get image from camera
     **/
    @IBAction func camera(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            self.cameraPicker.delegate = self
            self.cameraPicker.sourceType = .camera
            self.cameraPicker.allowsEditing = true
            self.present(self.cameraPicker, animated: true)
        } else {
            print("Camera not available!")
        }
        
    }
    
    /*
     apply style action
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
    
    /*
     show popview on the bottom when the process of applying style was finished
     **/
    func showPopView(){
        let alert = UIAlertController(title: NSLocalizedString("action", comment: ""), message: NSLocalizedString("please_choose_one_action", comment: ""), preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: NSLocalizedString("cancle", comment: ""), style:.default, handler: nil)
        let save = UIAlertAction(title: NSLocalizedString("save", comment: ""), style: .default, handler: {
            ACTION in
            self.saveImage()
        })
        let share = UIAlertAction(title: NSLocalizedString("share", comment: ""), style: .default, handler: {
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
        
        self.view.makeToast(NSLocalizedString("save_image_success", comment: ""), duration: 3.0, position: .center)
    }
    
    /*
     share to the social media action
     **/
    func shareSocialMedia(){
        // save image before you share the image
        saveImage()
        // share function
        let activityVC = UIActivityViewController(activityItems: [self.imageView.image!, NSLocalizedString("share_image", comment: "")], applicationActivities: nil)
        activityVC.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            if error != nil {
                self.view.makeToast("Error:\(error!.localizedDescription)")
                return
            }
            if completed {
                self.view.makeToast(NSLocalizedString("share_successful", comment: ""))
            }
        }
        self.present(activityVC, animated: true, completion: nil)
    }
}

/*
 Image Picker UI Controller
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
 CollectionView
 **/
extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    // for UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }

    /*
     for each cell
     **/
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        self.collectionView = collectionView
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
            if candyDownloadStatus == 0{
                cell.imageView.image = #imageLiteral(resourceName: "candydownload")
            }else if candyDownloadStatus == 1{
                cell.imageView.image = #imageLiteral(resourceName: "candydownloading")
            }else{
                cell.imageView.image = #imageLiteral(resourceName: "candy")
                self.view.makeToast(NSLocalizedString("download_done", comment: ""))
            }
        case 7:
            cell.lbl.text = items[7]
            cell.imageView.image = #imageLiteral(resourceName: "wave")
        default:
            cell.lbl.text = ""
        }
        return cell
    }

    /*
     for UICollectionViewDelegate
     **/
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.collectionView = collectionView
        self.imageView.image = self.selectedImage
        if indexPath.item == 0 {
            return
        }
        if indexPath.item == 7 {
            // xiaoyu: 跳到付款界面
            print("payment function!")
            return
        }
        self.selectedModel = AllModel.allCases[indexPath.item - 1]
        // item 6->candy style->need to download first
        if indexPath.item == 6 {
            // xiaoyu: (modify it later), if the Candy Model file path is exist, download start
//            let filePath = downloadUtil.modelFilePath(filename: "FNS-Candy.mlmodelc")
//            print("collectionView, filePath:\(filePath)")
//            let fileManager = FileManager.default
//            if !fileManager.fileExists(atPath: filePath) {
            // xiaoyu: (modify it later), if the Candy Model file path is exist, download end
            downloadModel = "FNS-Candy"
            if candyDownloadStatus == 0{
                self.downloadModel(url: self.urlCandyModelCloud)
                return
            }
        }
        applyStyle()
    }
}

/*
 URLSession for download models function
 **/
extension ViewController: URLSessionDataDelegate{
    /*
     when receive the response from the server, completionHandler(.allow) is to receive
     the data
     **/
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        print("response start...")
        completionHandler(.allow)
    }
    
    /*
     receive data
     **/
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("receive data...")
        candyDownloadStatus = 1
        if self.responseData == nil{
            self.responseData = Data.init()
        }
        self.responseData?.append(data)
        downloadUtil.saveData(data: self.responseData!, filename: "/\(downloadModel).mlmodel")
        
        // give the result to main thread
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }
    
    /*
     download done
     **/
    internal func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?){
        print("download done...")
        // when we finish download operation, compile and save to the permanent location
        // if there are more downloaded models except candy, just add case in switch
        let isSuccess = downloadUtil.compileToPermanentLocation(filename: "/\(downloadModel).mlmodel")
        if isSuccess {
            switch downloadModel {
            default:
                candyDownloadStatus = 2
            }
        }else{
            switch downloadModel {
            default:
                candyDownloadStatus = 0
            }
        }
        
        // give the result to main thread
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
            self.session?.invalidateAndCancel()
            self.session = nil
            self.responseData = nil
        }
    }
    
    /*
     for certification
     **/
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("urlsession, ignore the certi...")
        if let aTrust = challenge.protectionSpace.serverTrust {
            completionHandler(URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: aTrust))
        }
    }
    
    /*
     download function
     **/
    func downloadModel(url: String) {
        print("downloadModel...")
        guard self.session == nil else{
            print("You are downloading!")
            return
        }
        // create the request
        var urlRequest = URLRequest(url: URL(string: url)!)
        urlRequest.httpMethod = "GET"
        // set for ignore the cache
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        // session
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        // create the task
        let downloadTask = session?.dataTask(with: urlRequest)
        // download
        downloadTask?.resume()
    }
    

}
