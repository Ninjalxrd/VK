//
//  ImageService.swift
//  Test
//
//  Created by Павел on 02.03.2025.
//

import Foundation
import UIKit

final class ImageService {
    
    static let cache: NSCache<NSURL, NSData> = NSCache()
    
    static let imageSession: URLSession = {
        let session = URLSession(configuration: .default)
        return session
    }()
    
    static func downloadImage(by stringURL: String) async throws -> UIImage? {
        guard let url = URL(string: stringURL) else { return nil }
        
        if let imageData = cache.object(forKey: url as NSURL) {
            return UIImage(data: imageData as Data)
        }
        
        let imageResponse = try await imageSession.data(from: url)
        cache.setObject(imageResponse.0 as NSData, forKey: url as NSURL)
        return UIImage(data: imageResponse.0)
    }
}
