//
//  KingfisherSource.swift
//  ImageSlideshow
//
//  Created by feiin
//
//

import UIKit
import Kingfisher

/// Input Source to image using Kingfisher
public class KingfisherSource: NSObject, InputSource {
    /// url to load
    public var url: URL?

    /// placeholder used before image is loaded
    public var placeholder: UIImage?

    /// options for displaying, ie. [.transition(.fade(0.2))]
    public var options: KingfisherOptionsInfo?
    
    public var contentMode: UIViewContentMode?

    /// Initializes a new source with a URL
    /// - parameter url: a url to be loaded
    /// - parameter placeholder: a placeholder used before image is loaded
    /// - parameter options: options for displaying
    public init(url: URL, placeholder: UIImage? = nil, options: KingfisherOptionsInfo? = nil, contentMode: UIViewContentMode? = nil) {
        self.url = url
        self.placeholder = placeholder
        self.options = options
        self.contentMode = contentMode
        super.init()
    }

    /// Initializes a new source with a URL string
    /// - parameter urlString: a string url to load
    /// - parameter placeholder: a placeholder used before image is loaded
    /// - parameter options: options for displaying
    public init?(urlString: String, placeholder: UIImage? = nil, options: KingfisherOptionsInfo? = nil, contentMode: UIViewContentMode? = nil) {
        if let validUrl = URL(string: urlString) {
            self.url = validUrl
            self.placeholder = placeholder
            self.options = options
            self.contentMode = contentMode
            super.init()
        } else {
            return nil
        }
    }
    
    public init?(urlString: String, placeHolderImage: UIImage? = nil, downloadApiURL: String, accessToken: String, xsrfToken: String, contentMode: UIViewContentMode? = nil) {
        super.init()
        if let validUrl = createURL(urlString, downloadApiURL: downloadApiURL) {
            self.url = validUrl
            self.placeholder = placeHolderImage
            self.options = createOptions(urlString, accessToken: accessToken, xsrfToken: xsrfToken)
            self.contentMode = contentMode
        } else {
            return nil
        }
    }

    /// Load an image to an UIImageView
    ///
    /// - Parameters:
    ///   - imageView: UIImageView that receives the loaded image
    ///   - callback: Completion callback with an optional image
    @objc
    public func load(to imageView: UIImageView, with callback: @escaping (UIImage?) -> Void) {
        imageView.contentMode = .center
        imageView.backgroundColor = UIColor(red: 245/255.0, green: 245/255.0, blue: 245/255.0, alpha: 1.0)
        imageView.kf.setImage(with: self.url, placeholder: self.placeholder, options: self.options, progressBlock: nil) { [weak self] result in
            switch result {
            case .success(let image):
                imageView.contentMode = self?.contentMode ?? .scaleAspectFit
                imageView.backgroundColor = .clear
                callback(image.image)
            case .failure:
                callback(self?.placeholder)
            }
        }
    }

    /// Cancel an image download task
    ///
    /// - Parameter imageView: UIImage view with the download task that should be canceled
    public func cancelLoad(on imageView: UIImageView) {
        imageView.kf.cancelDownloadTask()
    }
    
    private func createURL(_ urlString: String, downloadApiURL: String) -> URL? {
        if isPrivateBucket(urlString) {
            return createPrivateURL(urlString, downloadApiURL: downloadApiURL)
        } else {
            return createPublicURL(urlString)
        }
    }
    
    private func createOptions(_ urlString: String, accessToken: String, xsrfToken: String) ->  [KingfisherOptionsInfoItem] {
        var options: [KingfisherOptionsInfoItem] = [.transition(.fade(0.2))]
        
        if isPrivateBucket(urlString) {
            options.append(.requestModifier(createPrivateBucketRequestModifier(urlString, accessToken: accessToken, xsrfToken: xsrfToken)))
        } else {
            options.append(.cacheOriginalImage)
        }
        
        return options
    }
    
    private func isPrivateBucket(_ urlString: String) -> Bool {
        return urlString.contains("private")
    }
    
    private func createPublicURL(_ urlString: String) -> URL? {
        return URL(string: urlString)
    }
    
    private func createPrivateURL(_ urlString: String, downloadApiURL: String) -> URL? {
        let appended = "?cahceString=\(urlString.createCacheString())"
        return URL(string: downloadApiURL + appended)
    }
    
    private func createPrivateBucketRequestModifier(_ urlString: String, accessToken: String, xsrfToken: String) -> AnyModifier {
        return AnyModifier { req in
            var request = req
            request.setValue(urlString, forHTTPHeaderField: "url")
            request.setValue(accessToken, forHTTPHeaderField: "Authorization")
            request.setValue(xsrfToken, forHTTPHeaderField: "x-xsrf-token")
            return request
        }
    }
}

fileprivate extension String {
    func createCacheString() -> String {
        return components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
    }
}
