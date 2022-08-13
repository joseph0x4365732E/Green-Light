//
//  Green_LightApp.swift
//  Green Light
//
//  Created by Joseph Cestone on 7/6/22.
//

import SwiftUI

@main
struct Green_LightApp: App {
    var body: some Scene {
        WindowGroup {
            SimulationView(simulationPlayer: SimulationPlayer(simulation: createHSSimulation(), time: 0))
        }
    }
}
