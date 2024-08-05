//
//  TileCellBackground.swift
//  TVGuideLayoutExample
//
//  Created by Jonathan Menard on 2024-08-09.
//

import UIKit

extension UIImage {
    static func createBackgroundTileCellImage() -> UIImage {
        var size = CGSize(width: 50.0, height: 50.0)
        
        let renderer = UIGraphicsImageRenderer(size: size)
                
        let image = renderer.image { graphicsImageRendererContext in
            let context = graphicsImageRendererContext.cgContext
            
            var rect = CGRect(origin: .zero, size: size)

            UIColor.darkBlue.setFill()
            context.fill(rect)
            
            let innerRect = rect.insetBy(dx: 2.0, dy: 2.0)
            
            UIColor.mediumBlue.setStroke()
            
            context.setLineWidth(2.0)
            context.move(to: CGPoint(x: innerRect.width, y: innerRect.minY))
            context.addLine(to: CGPoint(x: innerRect.minX, y: innerRect.minY))
            context.addLine(to: CGPoint(x: innerRect.minX, y: innerRect.height))
            
            context.strokePath()
        }
        
        return image.resizableImage(withCapInsets: UIEdgeInsets(
            top: 5.0,
            left: 5.0,
            bottom: 5.0,
            right: 5.0), resizingMode: .stretch)
    }
}
