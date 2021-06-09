//
//  Photo.swift
//  Virtual Tourist
//
//  Created by GOZDE KARDAS on 9.06.2021.
//
import Foundation

struct PhotoResponse: Codable {
    
    let imageURL: String?
    
    enum CodingKeys: String, CodingKey{
        case imageURL = "url_m"
    }
}
