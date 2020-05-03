//
//  DownloadUtil.swift
//  NeuralStyleTransfer
//
//  Created by Xiaoyu Wang on 4/25/20.
//  Copyright © 2020 Xiaoyu Wang. All rights reserved.
//

import UIKit
import CoreML

class DownloadUtil: NSObject {

    /*
     save to file system
     **/
    func saveData(data: Data, filename: String) {
        let nsMutableData = NSMutableData()
        nsMutableData.append(data)
        print("saveData, path:\(dataFilePath(filename: filename))")
        // write to document file
        // xiaoyu: 下载写到document还有问题，后面需要改
        nsMutableData.write(toFile: dataFilePath(filename: filename), atomically: true)
    }
    
    /*
     compile the data of model and move it to a permanent location
     https://developer.apple.com/documentation/coreml/core_ml_api/downloading_and_compiling_a_model_on_the_user_s_device
     **/
    func compileToPermanentLocation(filename: String){
        // get downloaded file path
        let filePath = dataFilePath(filename: filename)
        // get the model url by downloaded file path
        let modelUrl: URL = URL.init(fileURLWithPath: filePath)
        print("compileToPermanentLocation, modelUrl:\(modelUrl)")
        var compiledUrl: URL?
        do{
            // compile the model and return the compiled model url
            compiledUrl = try MLModel.compileModel(at: modelUrl)
            print("compileToPermanentLocation, compiledUrl:\(compiledUrl!)")
        }catch{
            print("Error: \(error.localizedDescription)")
            return
        }
        
        let fileManager = FileManager.default
        // get the directory that was used to store the compiled model
        let appfilepath = appFilePath()
        let appfilepathUrl = URL(string: appfilepath)
        // get the final model path
        let permanentUrl = appfilepathUrl!.appendingPathComponent(compiledUrl!.lastPathComponent)
        print("compileToPermanentLocation, permanentUrl:\(permanentUrl.absoluteString)")
        do {
            // if the file exists, replace it. Otherwise, copy the file to the destination.
            if fileManager.fileExists(atPath: permanentUrl.absoluteString) {
                _ = try fileManager.replaceItemAt(permanentUrl, withItemAt: compiledUrl!)
            } else {
                try fileManager.copyItem(at: compiledUrl!, to: permanentUrl)
            }
        } catch {
            print("Error during copy: \(error.localizedDescription)")
        }
    }
    
    /*
     get the app directory which was used to save the compiled model(xxx.mlmodelc/)
     **/
    func appFilePath ()->String{
        // will have permission in the real device when we try to write to this directory
        // so using documentsDirectory instead of it
        // let path = Bundle.main.bundleURL.absoluteString
        var path = self.documentsDirectory()
        path = "file://" + path + "/"
        return path
    }
    
    /*
     get model directory
     **/
    func modelFilePath(filename: String)->String{
        return appFilePath().appendingFormat(filename)
    }
    
    /*
     get the directory which was used to save the downloaded model for temporary
     **/
    func dataFilePath (filename: String)->String{
        return self.documentsDirectory().appendingFormat(filename)
    }
    
    /*
     get the sandy box documents directory
     **/
    func documentsDirectory()->String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths.first!
        return documentsDirectory
    }

}
