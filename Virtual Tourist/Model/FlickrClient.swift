//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by GOZDE KARDAS on 8.06.2021.
//

import Foundation


class FlickrClient{
     static let apiKey = "0d9acecb0dc70f5f4777ab3352b4f159"
     static let secretKey = "5ec69019dddc54a6"
    
    enum Endpoints {
            
            
            static let baseURL = "https://www.flickr.com/services/rest/?method="
            
            case searchPhotos(latitude:Double, longitude:Double)
            
            var stringURL: String{
                switch self {
                case let .searchPhotos(latitude, longitude):
                    return Endpoints.baseURL + "flickr.photos.search&" + "api_key=\(FlickrClient.apiKey)&" + "sort=date-posted-asc&" +
                        "&privacy_filter=1" + "media=photos&" + "lat=\(latitude)&lon=\(longitude)&" + "extras=url_m&" + "per_page=12&" + "page=\(Int.random(in: 0..<100))&" + "format=json&nojsoncallback=1"
                }
            }
            var url: URL{
                return URL(string: stringURL)!
            }
        }
    
    private class func sendGETRequest<ResponseType: Decodable>(url: URL, response: ResponseType.Type, completionHandler: @escaping (ResponseType?,Error?) -> Void ){
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data else {
                    DispatchQueue.main.async {
                        completionHandler(nil,error)
                    }
                    return
                }
                
                print(String(data: data, encoding: .utf8)!)

                let decoder = JSONDecoder()
                do {
                    let responseObject = try decoder.decode(ResponseType.self, from: data)
                    DispatchQueue.main.async {
                        completionHandler(responseObject,nil)
                    }
                }
                catch {
                    DispatchQueue.main.async {
                        completionHandler(nil, error)
                    }
                }
            }
            task.resume()
        }
    
    public class func flickrGETSearchPhotos(lat: Double, lon: Double, completionHandler: @escaping ([PhotoResponse], Error?) -> Void ){
            
        sendGETRequest(url: Endpoints.searchPhotos(latitude: lat, longitude: lon).url, response: SearchResponse.self) { (response, error) in
                if let response = response {
                    completionHandler(response.photos.photo, nil)
                } else {
                    completionHandler([], error)
                }
            }
        }
    public class func downloadImage(imageURL: URL, completionHandler: @escaping (Data?, Error?) -> Void ){
                    
            let task = URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
                guard let data = data else {
                    DispatchQueue.main.async {
                        completionHandler(nil, error)
                    }
                return
                }
                DispatchQueue.main.async {
                    completionHandler(data,nil)
                }
            }
            task.resume()
        }
    
}
