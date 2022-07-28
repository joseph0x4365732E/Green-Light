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
let laneCenter = laneWidth / 2
let halfRoad = roadWidth / 2
let plotDist = 1320.0 // 1/4 Mile
let stripeWidth = 0.3
let fullRoadWidth = roadWidth + stripeWidth
let stripeLength = 1.5
let stripeSpacing = 6.0
let teslaWidth = 82.2 / 12
let teslaLength = 184.8 / 12
let carSpacing = 24.0

let carImage = UIImage(named: "Car")!

let fullPlotMeters = meters(from: 2 * plotDist)
let satZoomMeters = fullPlotMeters / 4
let zoomedPlotMeters = fullPlotMeters / 16


struct Car {
    var location: CLLocationCoordinate2D
    var direction: CLLocationDirection
}

struct Route {
    var points: [CLLocationCoordinate2D]
    var cars: [Car]
    
    init(cars: [Car] = [], points: [CLLocationCoordinate2D]) {
        self.points = points
        self.cars = cars
    }
    
    init(cars: [Car] = [], points: () -> [CLLocationCoordinate2D]) {
        self.points = points()
        self.cars = cars
    }
}

// MARK: Intersection
struct Intersection {
    var center: CLLocationCoordinate2D
    var bounds: [CLLocationCoordinate2D]
    var routes: [Route]
    
    init(center: CLLocationCoordinate2D, routes: [Route], bounds: [CLLocationCoordinate2D]) {
        self.center = center
        self.bounds = bounds
        self.routes = routes
    }
    
    init(center: CLLocationCoordinate2D, routes: [Route], bounds: ()->[CLLocationCoordinate2D]) {
        self.center = center
        self.bounds = bounds()
        self.routes = routes
    }
    
    // MARK: Lines
    var boundsLine: ColorPolyline {
        ColorPolyline(
            polyline: MKPolyline(coordinates: bounds, count: bounds.count),
            color: UIColor.systemRed
        )
    }
    var routesLines: [ColorPolyline] {
        routes.map { route in
            ColorPolyline(polyline: MKPolyline(coordinates: route.points, count: route.points.count), color: UIColor.systemBlue)
        }
    }
    var lines: [ColorPolyline] { [boundsLine] + routesLines }
}

//MARK: arc()

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

func meters(from feet: Double) -> Double { feet / 3.28084 }

//MARK: Examples

let hSCentr =
CLLocationCoordinate2D(
    latitude: 35.23794,
    longitude: -119.05679
)
//Cars
let car1 = Car(location: hSCentr.offset(latFeet: -laneCenter, longFeet: laneCenter), direction: 0)
let car2 = Car(location: hSCentr.offset(latFeet: -laneCenter, longFeet: 0), direction: 0)
let northboundCars = [car1, car2]

//Routes
let northbound = Route(cars: northboundCars) {
    let sFarPoint = hSCentr.offset(latFeet: -plotDist, longFeet: laneCenter)
    let nFarPoint = hSCentr.offset(latFeet: plotDist, longFeet: laneCenter)
    
    return [sFarPoint, nFarPoint]
}
let eastbound = Route {
    let wFarPoint = hSCentr.offset(latFeet: -laneCenter, longFeet: -plotDist)
    let eFarPoint = hSCentr.offset(latFeet: -laneCenter, longFeet: plotDist)
    
    return [wFarPoint, eFarPoint]
}

//Intersection
let houghtonAndStine = Intersection(center: hSCentr, routes: [northbound, eastbound]) {
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

