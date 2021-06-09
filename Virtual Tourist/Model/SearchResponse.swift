//
//  SearchResponse.swift
//  Virtual Tourist
//
//  Created by GOZDE KARDAS on 9.06.2021.
//
import Foundation

struct SearchResponse: Codable {
    let photos: PhotosResponse
    let stat: String
}
