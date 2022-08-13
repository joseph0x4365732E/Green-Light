//
//  ImageOverlay.swift
//  Green Light
//
//  Created by Joseph Cestone on 7/16/22.
//

import Foundation
import MapKit

//https://stackoverflow.com/questions/34857515/how-do-i-create-an-image-overlay-and-add-to-mkmapview-in-swift-2
public class ImageOverlay : NSObject, MKOverlay {
    let image:UIImage
    public let coordinate: CLLocationCoordinate2D
    let direction: CLLocationDirection
    public var boundingMapRect: MKMapRect
    let widthFeet: Double
    let heightFeet: Double
    
    init(image: UIImage, coordinate: CLLocationCoordinate2D, direction: CLLocationDirection, widthFeet: Double, heightFeet: Double) {
        self.image = image
        self.coordinate = coordinate
        self.direction = direction
        self.boundingMapRect = MKMapRect(origin: MKMapPoint(coordinate), size: MKMapSize())
        self.widthFeet = widthFeet
        self.heightFeet = heightFeet
    }
    
    convenience init(car: Car, road: Road) {
        self.init(
            image: carImage,
            coordinate: road.location(of: car),
            direction: road.direction(of: car),
            widthFeet: teslaWidth,
            heightFeet: teslaLength
        )
    }
}

public class ImageOverlayRenderer : MKOverlayRenderer {
    public override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        // Untransformed
        guard let overlay = self.overlay as? ImageOverlay else {
            return
        }
        let coord1 = MKMapPoint(overlay.coordinate.offset(latFeet: overlay.heightFeet / 2, longFeet: -overlay.widthFeet / 2))
        let coord2 = MKMapPoint(overlay.coordinate.offset(latFeet: -overlay.heightFeet / 2, longFeet: overlay.widthFeet / 2))
        let pt1 = self.point(for: coord1)
        let pt2 = self.point(for: coord2)
        let size = CGRect(pt1: pt1, pt2: pt2).size
        let maxDimension = max(size.height, size.height)
        let center = self.point(for: MKMapPoint(overlay.coordinate))
            .offset(deltaX: (maxDimension - size.width) * 0.5, deltaY: (maxDimension - size.height) * 0.5)
        let radians = overlay.direction * .pi / 180
        let tf =
        CGAffineTransform(translationX: maxDimension * 0.5, y: maxDimension * 0.5)
            .rotated(by: radians)
            .translatedBy(x: maxDimension * -1, y: maxDimension * -1)
        let rect = CGRect(origin: center, size: size)
        // Transformation
        context.concatenate(tf)
        UIGraphicsPushContext(context)
        overlay.image.draw(in: rect)
        UIGraphicsPopContext()
    }
}
