//
//  LightAnnotation.swift
//  Green Light
//
//  Created by Joseph Cestone on 7/15/22.
//

import Foundation
import MapKit

public class LightAnnotation: NSObject, MKAnnotation, Identifiable {
    public var coordinate: CLLocationCoordinate2D
    public var id: String
    init(coordinate: CLLocationCoordinate2D, id: String) {
        self.coordinate = coordinate
        self.id = id
        super.init()
    }
}

