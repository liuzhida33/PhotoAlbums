//
//  PhotoAlbums.swift
//  JoyLife
//
//  Created by 刘志达 on 2020/12/12.
//  Copyright © 2020 JoyLife. All rights reserved.
//

import Foundation

enum PhotoAlbums {
    case `default`

    func album() -> PhotoAlbumHandler {
        return PhotoAlbum()
    }
}
