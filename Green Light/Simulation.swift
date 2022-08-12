//
//  Simulation.swift
//  Green Light
//
//  Created by Joseph Cestone on 8/1/22.
//

import Foundation
import CoreLocation

class Simulation {
    static let timeTick: TimeInterval = 0.1
    static let forwardLookingTime: TimeInterval = 10
    
    var intersection: Intersection // Roads, bounds - static
    var signal: Signal
    var slices: [TimeSlice] = []
    var computer: SignalComputer
    
    init(intersection: Intersection, signal: Signal, computer: SignalComputer) {
        self.intersection = intersection
        self.signal = signal
        self.computer = computer
    }
}

struct TimeSlice {
    var routeSlices: [RouteSlice]
    var signalState: SignalState
    
    var totalSpeed: CLLocationSpeed {
        routeSlices.map { $0.totalSpeed }.reduce(0, +)
    }
    
    func advanced(byTime dt: TimeInterval, given nextSignalState: SignalState, at signal: Signal) -> TimeSlice {
        let newRouteSlices = routeSlices.map { routeSlice in
            let routeLight = signal.read(state: nextSignalState, road: routeSlice.road)
            return routeSlice.advanced(byTime: dt, watching: routeLight)
        }
        return TimeSlice(routeSlices: newRouteSlices, signalState: nextSignalState)
    }
}

protocol SignalComputer {
    func nextSignal(after slice: TimeSlice) -> SignalState
}

class MaxFwdAccComputer: SignalComputer {
    var signal: Signal
    
    init(signal: Signal) {
        self.signal = signal
    }
    
    func nextSignal(after slice: TimeSlice) -> SignalState {
        let numSlices = Int(Simulation.forwardLookingTime / Simulation.timeTick)
        
        let branches:[[TimeSlice]] = signal.possibleStates(following: slice.signalState).map { signalState in
            var previousSlice = slice
            return (0..<numSlices).map { _ in
                previousSlice = previousSlice.advanced(byTime: Simulation.timeTick, given: signalState, at: signal)
                return previousSlice
            }
        }
        let originalSpeed = slice.totalSpeed
        let accelerations = branches.map { slices in
            slices.last!.totalSpeed - originalSpeed
        }
        let fastestBranchIndex = accelerations.firstIndex(of: accelerations.max()!)!
        let nextSignal = branches[fastestBranchIndex].first!.signalState
        return nextSignal
    }
}
