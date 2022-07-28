//
//  SignalAnnotation.swift
//  Green Light
//
//  Created by Joseph Cestone on 7/15/22.
//

import Foundation
import MapKit

class SignalAnnotation: NSObject, MKAnnotation, Identifiable {
    var coordinate: CLLocationCoordinate2D
    var id: String
    init(coordinate: CLLocationCoordinate2D, id: String) {
        self.coordinate = coordinate
        self.id = id
        super.init()
    }
}

