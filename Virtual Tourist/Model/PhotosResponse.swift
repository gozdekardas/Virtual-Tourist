//
//  Photos.swift
//  Virtual Tourist
//
//  Created by GOZDE KARDAS on 9.06.2021.
//
import Foundation

struct PhotosResponse: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: Int
    let photo: [PhotoResponse]
    
    enum CodingKeys: String, CodingKey {
        case page
        case pages
        case perpage
        case total
        case photo
    }
}
