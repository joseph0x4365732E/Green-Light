//
//  Intersection.swift
//  Green Light
//
//  Created by Joseph Cestone on 7/14/22.
//

import Foundation
import MapKit

// MARK: Constants

let laneWidth = 12.0
let lanesWide = 2.0
let roadWidth = laneWidth * lanesWide
let halfRoad = roadWidth / 2
let plotDist = 1320.0 // 1/4 Mile
let stripeWidth = 0.3
let fullRoadWidth = roadWidth + stripeWidth
let stripeLength = 1.5
let stripeSpacing = 6.0
let teslaWidth = 72.8 / 12
let teslaLength = 184.8 / 12
let carSpacing = 24.0

let fullPlotMeters = meters(from: 2 * plotDist)

//class PolyRegion {
//    var points: [CLLocationCoordinate2D]
//
//    func contains(pt: CLLocationCoordinate2D) -> Bool {
//        return false
//    }
//}

struct Car {
    var location: CLLocationCoordinate2D
}

struct Route {
    var points: [CLLocationCoordinate2D]
    var cars: [Car] = []
    
    init(points: [CLLocationCoordinate2D]) {
        self.points = points
    }
    
    init(points: () -> [CLLocationCoordinate2D]) {
        self.points = points()
    }
}

struct Intersection {
    var region: MKCoordinateRegion
    var bounds: [CLLocationCoordinate2D]
    var routes: [Route]
    
    init(region: MKCoordinateRegion, routes: [Route], bounds: [CLLocationCoordinate2D]) {
        self.region = region
        self.bounds = bounds
        self.routes = routes
    }
    
    init(region: MKCoordinateRegion, routes: [Route], bounds: ()->[CLLocationCoordinate2D]) {
        self.region = region
        self.bounds = bounds()
        self.routes = routes
    }
}

func arc(radiusFeet: CLLocationDistance, center: CLLocationCoordinate2D, start: CLLocationDirection, end: CLLocationDirection, resolution: CLLocationDistance) -> [CLLocationCoordinate2D] {
    
    let backwards = start > end // goes negative
    
    // Should all be degrees
    let angleResolutionDeg = asin(resolution / radiusFeet) * 180 / .pi
    let totalAngle = abs(start - end)
    let numPoints = Int(ceil(totalAngle / angleResolutionDeg)) + 1 // add one for end point
    let actualResolution = (backwards ? -totalAngle : totalAngle) / Double(numPoints - 1)
    let thetas:[CLLocationDirection] =
    [start] +
    (2..<numPoints)
        .map { pointIndex in
            start + Double(pointIndex) * actualResolution
        } +
    [end]
    
    return thetas.map { theta in
        CLLocationCoordinate2D(radiusFeet: radiusFeet, theta: theta, relativeTo: center)
    }
}

let hSCentr =
CLLocationCoordinate2D(
    latitude: 35.23794,
    longitude: -119.05679
)

func meters(from feet: Double) -> Double {
    feet / 3.28084
}

let northBound = Route {
    let laneCenter = laneWidth / 2
    let sFarPoint = hSCentr.offset(latFeet: -plotDist, longFeet: laneCenter)
    let nFarPoint = hSCentr.offset(latFeet: plotDist, longFeet: laneCenter)
    
    return [sFarPoint, nFarPoint]
}
let eastBound = Route {
    let laneCenter = laneWidth / 2
    let wFarPoint = hSCentr.offset(latFeet: -laneCenter, longFeet: -plotDist)
    let eFarPoint = hSCentr.offset(latFeet: -laneCenter, longFeet: plotDist)
    
    return [wFarPoint, eFarPoint]
}
let houghtonAndStine = Intersection(
    region:
        MKCoordinateRegion(
            center: hSCentr,
            latitudinalMeters: fullPlotMeters,
            longitudinalMeters: fullPlotMeters
        ),
    routes: [northBound, eastBound]
    ) {
        
        let curbRadius = 25.0;
        let farENEPoint = hSCentr
            .offset(
                latFeet: halfRoad, // y
                longFeet: plotDist // x
            )
        let eNEpoint = hSCentr.offset(latFeet: halfRoad, longFeet: halfRoad + curbRadius)
        let nEArcCenter = hSCentr.offset(latFeet: halfRoad + curbRadius, longFeet: halfRoad + curbRadius)
        let nNEPoint = hSCentr.offset(latFeet: halfRoad + curbRadius, longFeet: halfRoad)
        let farNNEPoint = hSCentr.offset(latFeet: plotDist, longFeet: halfRoad)
        
        let eNELine = [farENEPoint, eNEpoint]
        let nNELine = [nNEPoint, farNNEPoint]

        let arcPoints:[CLLocationCoordinate2D] = arc(radiusFeet: curbRadius, center: nEArcCenter, start: 180, end: 90, resolution: 1) // EDIT increase resolution
        
        let nEPoints = eNELine + arcPoints + nNELine
        let nLat = nEPoints.map(\.latitude)
        let eLong = nEPoints.map(\.longitude)
        let sLat = nLat.map { -$0 }
        let wLong = eLong.map { -$0 }

        let nWPoints:[CLLocationCoordinate2D] = nEPoints.map { $0.mirroredAcross(long: hSCentr.longitude) }.reversed()
        let sWPoints:[CLLocationCoordinate2D] = nWPoints.map { pt in // flip across x axis
            pt.mirroredAcross(lat: hSCentr.latitude)
        }.reversed()
        let sEPoints:[CLLocationCoordinate2D] = nEPoints.map { pt in // flip across x axis
            pt.mirroredAcross(lat: hSCentr.latitude)
        }.reversed()
        
        return nEPoints + nWPoints + sWPoints + sEPoints
    }

