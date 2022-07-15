//
//  IntersectionView.swift
//  Green Light
//
//  Created by Joseph Cestone on 7/6/22.
//

import SwiftUI
import MapKit

//https://gist.github.com/shaundon/00be84deb3450e31db90a31d5d5b7adc/raw/d010d68ac08e49f50603d4006ccbb051cc807902/MapView.swift

struct IntersectionView: View {
    @State var region =
    MKCoordinateRegion(
        center:
            CLLocationCoordinate2D(
                latitude: 35.23794,
                longitude: -119.05679
            ),
        latitudinalMeters: fullPlotMeters / 8,
        longitudinalMeters: fullPlotMeters / 8
    )
    @State var intersection: Intersection
    @State var zoomedIn = true
    
    var boundsLine: ColorPolyline {
        ColorPolyline(
            polyline: MKPolyline(coordinates: intersection.bounds, count: intersection.bounds.count),
            color: UIColor.systemRed
        )
    }
    
    var routesLines: [ColorPolyline] {
        intersection.routes.map { route in
            ColorPolyline(polyline: MKPolyline(coordinates: route.points, count: route.points.count), color: UIColor.systemBlue)
            
        }
    }
    
    var lines: [ColorPolyline] { [boundsLine] + routesLines }

    
    func toggleZoom() {
        zoomedIn.toggle()
        let zoomSize = zoomedIn ? fullPlotMeters / 8 : fullPlotMeters
        region =
        MKCoordinateRegion(
            center: hSCentr,
            latitudinalMeters: zoomSize,
            longitudinalMeters: zoomSize
        )
    }
    
    func overlayButtons() -> some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                VStack(spacing: 0) {
                    Button {
                        withAnimation() {
                            toggleZoom()
                        }
                    } label: {
                        Image(systemName: "scope")
                            .resizable()
                            .imageScale(.large)
                            .scaledToFit()
                            .padding(10)
                    }
                    Divider()
                    Button {

                    } label: {
                        Image(systemName: "play")
                            .resizable()
                            .imageScale(.large)
                            .scaledToFit()
                            .padding(14)
                    }
                }
                .frame(width: 50)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color(uiColor: .systemGray6)))
                .padding(.horizontal)
            }
            Spacer()
        }
    }

    var body: some View {
        ZStack {
            GeometryReader { geom in
                MapView(region: $region, polylines: lines)
            }
            .edgesIgnoringSafeArea(.all)
            
            overlayButtons()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        IntersectionView(intersection: houghtonAndStine)
    }
}
