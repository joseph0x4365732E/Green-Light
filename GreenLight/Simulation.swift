//
//  Simulation.swift
//  Green Light
//
//  Created by Joseph Cestone on 8/1/22.
//

import Foundation
import CoreLocation

public class Simulation {
    static let timeTick: TimeInterval = 0.1
    static let forwardLookingTime: TimeInterval = 10
    
    var intersection: Intersection // Roads, bounds - static
    var signal: Signal
    var computer: SignalComputer
    var runTime: TimeInterval
    var slices: [TimeSlice]
    var hasRun: Bool = false
    
    init(intersection: Intersection, signal: Signal, computer: SignalComputer, runTime: TimeInterval, initialSlice: TimeSlice) {
        self.intersection = intersection
        self.signal = signal
        self.computer = computer
        assert(runTime > Simulation.timeTick, "Simuation runtime too short: Runtime \(runTime) is less than Simulation.timeTick of \(Simulation.timeTick).")
        self.runTime = runTime
        self.slices = [initialSlice]
    }
    
    func run() {
        let numSlices = Int(runTime / Simulation.timeTick)
        guard !hasRun else { return }
        var previousSlice = slices.first!
        slices = (0..<numSlices).map { _ in
            let nextSignalState = computer.nextSignal(after: previousSlice)
            previousSlice = previousSlice.advanced(byTime: Simulation.timeTick, given: nextSignalState, at: signal)
            return previousSlice
        }
        hasRun = true
    }
}

public struct TimeSlice {
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

public protocol SignalComputer {
    func nextSignal(after slice: TimeSlice) -> SignalState
}

/// Maximizes Acceleration by looking forward `Simulation.forwardLookingTime` seconds
public class MaxFwdAccComputer: SignalComputer {
    var signal: Signal
    
    init(signal: Signal) {
        self.signal = signal
    }
    
    public func nextSignal(after slice: TimeSlice) -> SignalState {
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
