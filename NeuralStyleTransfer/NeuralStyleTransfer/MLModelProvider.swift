//
//  MLModelProvider.swift
//  NeuralStyleTransfer
//
//  Created by Xiaoyu Wang on 3/14/20.
//  Copyright © 2020 Xiaoyu Wang. All rights reserved.
//

import UIKit
import CoreML

// define all of the models
enum AllModel : String, CaseIterable {
    
    case pointllism = "Pointillism"
    case starrynight = "StarryNight"
    case scream = "FNS-The-Scream"
    case muse = "FNS-La-Muse"
    case udnie = "FNS-Udnie"
    case candy = "FNS-Candy"
    
    func modelProvider() throws -> MLModelProvider {
        let downLoadUtil: DownloadUtil = DownloadUtil()
        print("which model:\(self.rawValue)")
        
        var url:URL?
   
        // set the URL, if it is download, get from document folder, else, get from
        // .app folder
        switch self {
        case .candy:
            guard let urlcandy = URL(string: downLoadUtil.modelFilePath(filename: "\(self.rawValue).mlmodelc")) else{
                throw ErrorUtil.assetPathError
            }
            url = urlcandy
        default:
            guard let urlother = Bundle.main.url(forResource: self.rawValue, withExtension:"mlmodelc")
            else {
                throw ErrorUtil.assetPathError
            }
            url = urlother
        }
        
        // set model
        switch self {
        case .pointllism:
            return try MLModelProvider(contentsOf: url!,
                                pixelBufferSize: CGSize(width:720, height:720),
                                inputName: "myInput",
                                outputName: "myOutput")
        case .starrynight:
            return try MLModelProvider(contentsOf: url!,
                                pixelBufferSize: CGSize(width:720, height:720),
                                inputName: "inputImage",
                                outputName: "outputImage")
        case .scream:
            return try MLModelProvider(contentsOf: url!,
                                pixelBufferSize: CGSize(width:720, height:720),
                                inputName: "inputImage",
                                outputName: "outputImage")
        case .muse:
            return try MLModelProvider(contentsOf: url!,
                                pixelBufferSize: CGSize(width:720, height:720),
                                inputName: "inputImage",
                                outputName: "outputImage")
        case .udnie:
            return try MLModelProvider(contentsOf: url!,
                                pixelBufferSize: CGSize(width:720, height:720),
                                inputName: "inputImage",
                                outputName: "outputImage")
        case .candy:
            return try MLModelProvider(contentsOf: url!,
                                pixelBufferSize: CGSize(width:720, height:720),
                                inputName: "inputImage",
                                outputName: "outputImage")
        }
    }
}

// Encapsulation class for our Neural Style Transfer models
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class MLModelProvider {
    var model: MLModel
    
    // The variable parameters for our Neural Style Transfer models
    var inputName: String
    var outputName: String
    var pixelBufferSize: CGSize
   
    init(contentsOf url: URL,
         pixelBufferSize: CGSize,
         inputName: String,
         outputName: String) throws {
        self.model = try MLModel(contentsOf: url)
        self.pixelBufferSize = pixelBufferSize
        self.inputName = inputName
        self.outputName = outputName
    }
    
    // Provide a more abstracted prediction method
    // Allowing for an UIImage input of any size
    // and returning the result as an UIImage of same size
    func prediction(inputImage: UIImage) throws -> UIImage {

        // 1 - Resize image to our model expected size
        guard let resizedImage = inputImage.resize(to: self.pixelBufferSize) else {
            throw ErrorUtil.resizeError
        }
        
        // 2 - Transform our UIImage to a PixelBuffer
        guard let cvBufferInput = resizedImage.pixelBuffer() else {
            throw ErrorUtil.pixelBufferError
        }
        
        // 3 -  Feed that PixelBuffer to the model (this is where the actual magic happens)
        let MLInput = MLModelProviderInput(inputImage: cvBufferInput,
                                           inputName: inputName)
        let output = try self.prediction(input: MLInput)
        
        // 4 - Transform PixelBuffer output to UIImage
        guard let outputImage = UIImage(pixelBuffer: output.outputImage) else {
            throw ErrorUtil.pixelBufferError
        }
        
        // 5 - Resize result back to the original input size
        guard let finalImage = outputImage.resize(to: inputImage.size) else {
            throw ErrorUtil.resizeError
        }

        return finalImage
    }
    
    // Prediction using our custom MLModelProviderInput and MLModelProviderOutput
    func prediction(input: MLModelProviderInput) throws -> MLModelProviderOutput {
        let outFeatures = try model.prediction(from: input)
        let result = MLModelProviderOutput(outputImage: outFeatures.featureValue(for: outputName)!.imageBufferValue!, outputName: outputName)
        return result
    }
}

// Model Prediction Input Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class MLModelProviderInput : MLFeatureProvider {
    
    var inputImage: CVPixelBuffer
    var inputName: String
    var featureNames: Set<String> {
        get { return [inputName] }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == inputName) {
            return MLFeatureValue(pixelBuffer: inputImage)
        }
        return nil
    }
    
    init(inputImage: CVPixelBuffer, inputName: String) {
        self.inputName = inputName
        self.inputImage = inputImage
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
class MLModelProviderOutput : MLFeatureProvider {
    
    let outputImage: CVPixelBuffer
    var outputName: String
    var featureNames: Set<String> {
        get { return [outputName] }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == outputName) {
            return MLFeatureValue(pixelBuffer: outputImage)
        }
        return nil
    }
    
    init(outputImage: CVPixelBuffer, outputName: String) {
        self.outputName = outputName
        self.outputImage = outputImage
    }
}
