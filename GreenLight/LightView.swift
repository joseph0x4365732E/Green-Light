//
//  LightView.swift
//  Green Light
//
//  Created by Joseph Cestone on 7/27/22.
//

import SwiftUI

public struct LightView: View {
    public var body: some View {
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

struct LightView_Previews: PreviewProvider {
    static var previews: some View {
        LightView()
            .background(Color.white)
    }
}
