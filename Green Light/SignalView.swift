//
//  SignalView.swift
//  Green Light
//
//  Created by Joseph Cestone on 7/27/22.
//

import SwiftUI

struct SignalView: View {
    var body: some View {
        VStack(spacing: 2.4) {
            Circle()
                .foregroundColor(.red)
            Circle()
                .foregroundColor(.yellow)
            Circle()
                .foregroundColor(.green)
        }
        .foregroundColor(.white)
        .padding(3.6)
        .background(Color.black)
        .cornerRadius(2.4)
        .frame(width: 12, height: 30)
    }
}

struct SignalView_Previews: PreviewProvider {
    static var previews: some View {
        SignalView()
            .background(Color.white)
    }
}
