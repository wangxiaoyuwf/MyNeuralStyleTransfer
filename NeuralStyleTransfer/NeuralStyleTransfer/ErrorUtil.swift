//
//  ErrorUtil.swift
//  NeuralStyleTransfer
//
//  Created by Xiaoyu Wang on 3/14/20.
//  Copyright © 2020 Xiaoyu Wang. All rights reserved.
//

import Foundation

public enum ErrorUtil : Error {
    case unknown
    case assetPathError
    case modelError
    case resizeError
    case pixelBufferError
    case predictionError
}

extension ErrorUtil: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error!"
        case .assetPathError:
            return "Model not found!"
        case .modelError:
            return "Model error!"
        case .resizeError:
            return "Resizing failed!"
        case .pixelBufferError:
            return "Pixel Buffer conversion failed!"
        case .predictionError:
            return "CoreML prediction failed!"
        }
    }
}
