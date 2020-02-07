//
//  FilterDemoImageView.swift
//  Impression
//
//  Created by Echo on 11/20/18.
//

import UIKit

class FilterDemoImageView: UIView {
    
    var originalImage: UIImage?
    
    var image: UIImage? {
        didSet {
            guard let imageView = imageView else {
                return
            }
            
            imageView.image = image
        }
    }
    var imageView: UIImageView?
    
    init(frame: CGRect, image: UIImage?) {
        super.init(frame: frame)
        self.originalImage = image
        self.image = image

        imageView = UIImageView(frame: bounds)
        imageView?.contentMode = .scaleAspectFit
        imageView?.image = image
        addSubview(imageView!)
        
        imageView?.translatesAutoresizingMaskIntoConstraints = false
        imageView?.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        imageView?.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        imageView?.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func restoreToProcessedImage() {
        imageView?.image = image
    }
    
    func restoreToOriginalImage() {
        imageView?.image = originalImage
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        restoreToOriginalImage()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        restoreToProcessedImage()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        restoreToProcessedImage()
    }
}
