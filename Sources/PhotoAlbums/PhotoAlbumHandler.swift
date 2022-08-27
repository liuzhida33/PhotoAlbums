//
//  PhotoAlbumHandler.swift
//  JoyLife
//
//  Created by 刘志达 on 2020/12/12.
//  Copyright © 2020 JoyLife. All rights reserved.
//

import UIKit
import Photos
import CoreLocation
import MobileCoreServices
import CoreServices

public protocol PhotoAlbumHandler {
    typealias PhotoAlbumResult = Result<PHAsset, PhotoAlbumError>
    
    func save(_ photo: UIImage, completionHandler: @escaping (PhotoAlbumResult) -> Void)
    func save(_ photo: UIImage, location: CLLocation?, meta: [AnyHashable: Any]?, completionHandler: @escaping (PhotoAlbumResult) -> Void)
}

extension PhotoAlbumHandler {
    
    public func save(_ photo: UIImage, completionHandler: @escaping (PhotoAlbumResult) -> Void) {
        save(photo, location: nil, meta: nil, completionHandler: completionHandler)
    }
    
    public func save(_ photo: UIImage, location: CLLocation?, meta: [AnyHashable: Any]?, completionHandler: @escaping (PhotoAlbumResult) -> Void) {
        
        // Check for permission
        if #available(iOS 14, *) {
            guard PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized ||
                    PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited else {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    // not authorized, end with error
                    guard status == .authorized || status == .limited else {
                        completionHandler(.failure(.authCancelled))
                        return
                    }
                    
                    // received authorization, try to save photo to album
                    save(photo, completionHandler: completionHandler)
                }
                return
            }
        } else {
            // Fallback on earlier versions
            guard case .authorized = PHPhotoLibrary.authorizationStatus() else {
                
                // not authorized, prompt for access
                PHPhotoLibrary.requestAuthorization { status in
                    // not authorized, end with error
                    guard case .authorized = status else {
                        completionHandler(.failure(.authCancelled))
                        return
                    }
                    
                    // received authorization, try to save photo to album
                    save(photo, completionHandler: completionHandler)
                }
                return
            }
        }
        
        if let meta = meta {
            // save the photo now... we have permission and the desired album
            insert(photo: photo, location: location, meta: meta, completionHandler: completionHandler)
        } else {
            // save the photo now... we have permission and the desired album
            insert(photo: photo, completionHandler: completionHandler)
        }
    }
    
    private func fetchAlbum(with albumName: String) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        
        return PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions).firstObject
    }
    
    private func createAlbum(with albumName: String, completionHandler: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
        }, completionHandler: completionHandler)
    }
    
    private func insert(photo: UIImage, completionHandler: @escaping (PhotoAlbumResult) -> Void) {
        var placeholder: PHObjectPlaceholder?
        
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: photo)
            request.creationDate = Date()
            
            guard let assetPlaceHolder = request.placeholderForCreatedAsset else {
                return
            }
            placeholder = assetPlaceHolder
            
        }, completionHandler: { success, error in
            guard success == true, error == nil,
                  let placeholder = placeholder,
                  let asset = PHAsset.fetchAssets(withLocalIdentifiers: [placeholder.localIdentifier], options: nil).firstObject else {
                completionHandler(.failure(.saveFailed))
                return
            }
            completionHandler(.success(asset))
        })
    }
    
    private func insert(photo: UIImage, location: CLLocation?, meta: [AnyHashable: Any], completionHandler: @escaping (PhotoAlbumResult) -> Void) {
        var placeholder: PHObjectPlaceholder?
        
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString.appending(".jpg"))
        
        guard let imageData = photo.jpegData(compressionQuality: 1.0),
              let imageRef = CGImageSourceCreateWithData((imageData as CFData), nil),
              let dest = CGImageDestinationCreateWithURL(tmpURL as CFURL, kUTTypeJPEG, 1, nil) else {
            completionHandler(.failure(.saveFailed))
            return
        }
        
        CGImageDestinationAddImageFromSource(dest, imageRef, 0, meta as CFDictionary)
        CGImageDestinationFinalize(dest)
        
        PHPhotoLibrary.shared().performChanges({
            guard let request = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: tmpURL) else {
                return
            }
            request.creationDate = Date()
            request.location = location
            
            guard let assetPlaceHolder = request.placeholderForCreatedAsset else {
                return
            }
            placeholder = assetPlaceHolder
            
        }, completionHandler: { success, error in
            guard success == true, error == nil,
                  let placeholder = placeholder,
                  let asset = PHAsset.fetchAssets(withLocalIdentifiers: [placeholder.localIdentifier], options: nil).firstObject else {
                completionHandler(.failure(.saveFailed))
                return
            }
            completionHandler(.success(asset))
        })
    }
}
