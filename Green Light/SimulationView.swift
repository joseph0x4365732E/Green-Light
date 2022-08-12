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
    @State var region: MKCoordinateRegion
    @State var intersection: Intersection
    @State var zoomedIn = true
    @State var satellite = false
    @State var mapType = MKMapType.standard
    @State var simRunning = false
    
    init(zoomMeters: CLLocationDistance = zoomedPlotMeters, intersection: Intersection) {
        self.region = MKCoordinateRegion(center: intersection.center, latitudinalMeters: zoomMeters, longitudinalMeters: zoomMeters)
        self.intersection = intersection
    }
    
    var annotations: [MKAnnotation] = []//[exampleLightAnnotation]
    var carOverlays: [MKOverlay] {
        []
//        intersection.roads.flatMap { road in
//            road.cars.map { car in
//                ImageOverlay(car: car) as MKOverlay
//            }
//        }
    }
    
    func toggleZoom() {
        let newSize = !zoomedIn ? (satellite ? satZoomMeters : zoomedPlotMeters) : fullPlotMeters
        region = MKCoordinateRegion(center: hSCentr, latitudinalMeters: newSize, longitudinalMeters: newSize )
        zoomedIn.toggle()
    }
    
    func toggleMapType() {
        satellite.toggle()
        mapType = satellite ? .satellite : .standard
    }
    
    func divider() -> some View {
        Group {
            Spacer()
            Divider()
            Spacer()
        }
    }
    
    func overlayButtons() -> some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                VStack(spacing: 0) {
                    Spacer()
                    Button(action: { withAnimation() { toggleZoom() } }, label: {
                        Image(systemName: "scope")
                    })
                    divider()
                    Button(action: { toggleMapType() }, label: {
                        Image(systemName: satellite ? "globe.americas.fill" : "map")
                    })
                    divider()
                    Button(action: {}, label: { Image(systemName: "play") })
                    Spacer()
                }
                .imageScale(.large)
                .aspectRatio(1/3.0, contentMode: .fit)
                .frame(width: 40)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color(uiColor: .systemGray6)))
                .padding()
            }
            Spacer()
        }
    }

    var body: some View {
        ZStack {
            MapView(region: $region, mapType: $mapType, overlays: .constant(carOverlays), polylines: intersection.lines, annotations: .constant(annotations))
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

let exampleLightAnnotation = LightAnnotation(coordinate: hSCentr.offset(latFeet: laneWidth * 4, longFeet: laneWidth * 3), id: "sig-from-intrsctn.swft") as MKAnnotation
