//
//  HoughtonAndStine.swift
//  Green Light
//
//  Created by Joseph Cestone on 7/28/22.
//

import Foundation
import CoreLocation


public let resolutionMeters:CLLocationDistance = 1

public let hSCentr =
CLLocationCoordinate2D(
    latitude: 35.23794,
    longitude: -119.05679
)

public func createHSRoads() -> (Road, Road) {
    let sFarPoint = hSCentr.offset(latFeet: -plotDist, longFeet: laneCenter)
    
    // MARK: Roads
    let northbound = Road(name: "Stine-NB", speedLimit: mps(fromMPH: 55), stopLineDistance: plotMeters - laneCenter) {
        let sFarPoint = hSCentr.offset(latFeet: -plotDist, longFeet: laneCenter) // redefinition as the same
        let nFarPoint = hSCentr.offset(latFeet: plotDist, longFeet: laneCenter)
        
        return line(from: sFarPoint, to: nFarPoint, resolution: resolutionMeters)
    }

    let eastbound = Road(name: "Houghton-EB", speedLimit: mps(fromMPH: 55), stopLineDistance: plotMeters - laneCenter) {
        let wFarPoint = hSCentr.offset(latFeet: -laneCenter, longFeet: -plotDist)
        let eFarPoint = hSCentr.offset(latFeet: -laneCenter, longFeet: plotDist)
        
        return line(from: wFarPoint, to: eFarPoint, resolution: resolutionMeters)
    }
    return (northbound, eastbound)
}

let (nb, eb) = createHSRoads()

// MARK: Intersection
public let houghtonAndStine = Intersection(center: hSCentr, roads: [nb, eb]) {
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

    let arcPoints:[CLLocationCoordinate2D] = arc(radiusFeet: curbRadius, center: nEArcCenter, start: 180, end: 90, resolution: resolutionMeters) // EDIT increase resolution
    
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

func createHSSignal() -> Signal {
    let houghtonStineLights = [
        Light(location: CLLocationCoordinate2D(latitude: 35.23800, longitude: -119.05677)),
        Light(location: CLLocationCoordinate2D(latitude: 35.23792, longitude: -119.05672))
    ]
    
    let houghtonStineSignal = Signal(lights: houghtonStineLights, roads: [nb, eb], roadCombinations: [[nb], [eb]])
    return houghtonStineSignal
}

let hsSignal = createHSSignal()

func createHSSimulation() -> Simulation {
    let car1 = Car(position: plotDist, speed: mps(fromMPH: 60))
    let car2 = Car(position: plotDist - laneCenter - teslaLength * 1.5, speed: mps(fromMPH: 45))
    let car3 = Car(position: plotDist - laneCenter - teslaLength * 3, speed: mps(fromMPH: 55))
    let northboundCars = [car1]//, car2, car3]
    let eastboundCars = [car2, car3]
    let hougtonStineSignalComputer = MaxFwdAccComputer(signal: hsSignal)

    let northboundInitRouteSlice = RouteSlice(road: nb, carsOldestFirst: northboundCars)
    let eastboundInitRouteSlice = RouteSlice(road: eb, carsOldestFirst: eastboundCars)
    let houghtonInitialRouteSlices = [northboundInitRouteSlice, eastboundInitRouteSlice]

    let houghtonInitialSlice = TimeSlice(routeSlices: houghtonInitialRouteSlices, signalState: hsSignal.allRed)

    let houghtonStineSimulation = Simulation(intersection: houghtonAndStine, signal: hsSignal, computer: hougtonStineSignalComputer, runTime: 10, initialSlice: houghtonInitialSlice)
    return houghtonStineSimulation
}

