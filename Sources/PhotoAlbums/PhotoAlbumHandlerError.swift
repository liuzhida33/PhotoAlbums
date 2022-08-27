//
//  PhotoAlbumHandlerError.swift
//  JoyLife
//
//  Created by 刘志达 on 2020/12/12.
//  Copyright © 2020 JoyLife. All rights reserved.
//

import Foundation

public enum PhotoAlbumError: Error {
    case unauthorized
    case authCancelled
    case albumNotExists
    case saveFailed
    case unknown
}

extension PhotoAlbumError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return NSLocalizedString("PhotoAlbumError.unauthorized", comment: "Not authorized to access photos. Enable photo access in the 'Settings' app to continue.")
        case .authCancelled:
            return NSLocalizedString("PhotoAlbumError.authCancelled", comment: "The authorization process was cancelled. You will not be able to save to your photo albums without authorizing access.")
        case .albumNotExists:
            return NSLocalizedString("PhotoAlbumError.albumNotExists", comment: "Unable to create or find the specified album.")
        case .saveFailed:
            return NSLocalizedString("PhotoAlbumError.saveFailed", comment: "Failed to save specified image.")
        case .unknown:
            return NSLocalizedString("PhotoAlbumError.unknown", comment: "An unknown error occured.")
        }
    }
}
