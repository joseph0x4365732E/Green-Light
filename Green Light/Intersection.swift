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

let plotMeters = meters(fromFT: plotDist)
let fullPlotMeters = meters(fromFT: 2 * plotDist)
let satZoomMeters = fullPlotMeters / 4
let zoomedPlotMeters = fullPlotMeters / 25

let gravity: CLLocationAcceleration = 9.8
let decelerationGs = 0.4
let yellowDecelerationRate: CLLocationAcceleration = meters(fromFT: 10)
let driverReactionTime = 1.0

// MARK: Intersection
struct Intersection {
    var center: CLLocationCoordinate2D
    var roads: [Road]
    var bounds: [CLLocationCoordinate2D]
    
    init(center: CLLocationCoordinate2D, roads: [Road], bounds: [CLLocationCoordinate2D]) {
        self.center = center
        self.roads = roads
        self.bounds = bounds
    }
    
    init(center: CLLocationCoordinate2D, roads: [Road], bounds: ()->[CLLocationCoordinate2D]) {
        self.center = center
        self.bounds = bounds()
        self.roads = roads
    }
    
    // MARK: Lines
    var boundsLine: ColorPolyline {
        ColorPolyline(
            polyline: MKPolyline(coordinates: bounds, count: bounds.count),
            color: UIColor.systemRed
        )
    }
    var roadsLines: [ColorPolyline] {
        roads.map { road in
            ColorPolyline(polyline: MKPolyline(coordinates: road.points, count: road.points.count), color: UIColor.systemBlue)
        }
    }
    var carLines: [ColorPolyline] {
        []
//        roads.flatMap { rte in
//            rte.cars
//        }.map { car in
//            let points = car.box
//            return ColorPolyline(polyline: MKPolyline(coordinates: points, count: points.count), color: .blue)
//        }
    }
    var lines: [ColorPolyline] { [boundsLine] + roadsLines + carLines }
}

// MARK: arc()

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

func meters(fromFT feet: Double) -> Double { feet * 0.304800609601 }

func mps(fromMPH mph: Double) -> Double { meters(fromFT: mph * 5280) / 3600 }
