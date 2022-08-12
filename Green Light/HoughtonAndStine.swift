//
//  HoughtonAndStine.swift
//  Green Light
//
//  Created by Joseph Cestone on 7/28/22.
//

import Foundation
import CoreLocation

let hSCentr =
CLLocationCoordinate2D(
    latitude: 35.23794,
    longitude: -119.05679
)

let sFarPoint = hSCentr.offset(latFeet: -plotDist, longFeet: laneCenter)
let car1 = Car(position: plotDist, speed: mps(fromMPH: 60))
//let car2 = Car(position: plotDist - laneCenter - teslaLength * 1.5, location: sFarPoint, direction: 0)
//let car3 = Car(position: plotDist - laneCenter - teslaLength * 3, location: sFarPoint, direction: 0)
let northboundCars = [car1]//, car2, car3]

// MARK: Roads
let northbound = Road(name: "Stine-NB", speedLimit: mps(fromMPH: 55), stopLineDistance: plotMeters - laneCenter) {
    let sFarPoint = hSCentr.offset(latFeet: -plotDist, longFeet: laneCenter) // redefinition as the same
    let nFarPoint = hSCentr.offset(latFeet: plotDist, longFeet: laneCenter)
    
    return [sFarPoint, nFarPoint]
}

let eastbound = Road(name: "Houghton-EB", speedLimit: mps(fromMPH: 55), stopLineDistance: plotMeters - laneCenter) {
    let wFarPoint = hSCentr.offset(latFeet: -laneCenter, longFeet: -plotDist)
    let eFarPoint = hSCentr.offset(latFeet: -laneCenter, longFeet: plotDist)
    
    return [wFarPoint, eFarPoint]
}

// MARK: Intersection
let houghtonAndStine = Intersection(center: hSCentr, roads: [northbound, eastbound]) {
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

