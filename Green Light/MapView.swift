//
//  MapView.swift
//  Green Light
//
//  Created by Joseph Cestone on 7/7/22.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    var mapView: MKMapView = MKMapView()
    
    @Binding var region: MKCoordinateRegion
    var polylines: [ColorPolyline]
    var overlays: [MKOverlay] {
        polylines.map(\.polyline)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.mapType = .satellite
        
        mapView.addOverlays(overlays)
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlays(overlays)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

class Coordinator: NSObject, MKMapViewDelegate {
    var myMap: MapView
    var colors: [MKPolyline: UIColor]
    
    init(_ map: MapView) {
        self.myMap = map
        let tuples = map.polylines.map {
            ($0.polyline, $0.color)
        }
        self.colors = Dictionary(tuples) { first, _ in
            first
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let routePolyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: routePolyline)
            renderer.strokeColor = colors[routePolyline]
            renderer.lineWidth = 1
            return renderer
        }
        return MKOverlayRenderer()
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        myMap.region = mapView.region
    }
//    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
//        myMap.region = mapView.region
//    }
}

struct MapView_Previews: PreviewProvider {
    struct MapView_PreviewProvider: View {
        @State private var region = MKCoordinateRegion(
            // Apple Park
            center: CLLocationCoordinate2D(latitude: 37.334803, longitude: -122.008965),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        private var polyline = ColorPolyline(polyline: MKPolyline(coordinates: [
            // Steve Jobs theatre
            CLLocationCoordinate2D(latitude: 37.330828, longitude: -122.007495),
            // Caffè Macs
            CLLocationCoordinate2D(latitude: 37.336083, longitude: -122.007356),
            // Apple wellness center
            CLLocationCoordinate2D(latitude: 37.336901, longitude:  -122.012345)
        ], count: 3), color: UIColor.systemGreen)
        
        var body: some View {
            MapView(region: $region, polylines: [polyline])
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    static var previews: some View {
        MapView_PreviewProvider()
    }
}
