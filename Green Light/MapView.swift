//
//  MapView.swift
//  Green Light
//
//  Created by Joseph Cestone on 7/7/22.
//

import SwiftUI
import MapKit

// MARK: MP ViewRepresentable
public struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var mapType: MKMapType
    @Binding var overlays: [MKOverlay]
    var polylines: [ColorPolyline]
    private var allOverlays: [MKOverlay] {
        overlays +
        polylines.map(\.polyline)
    }
    @Binding var annotations: [MKAnnotation]
    
    public func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.mapType = mapType
        mapView.addOverlays(allOverlays)
        mapView.addAnnotations(annotations)
        return mapView
    }
    
    public func updateUIView(_ view: MKMapView, context: Context) {
        view.setRegion(region, animated: true)
        view.mapType = mapType
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

// MARK: Coordinator
public class Coordinator: NSObject, MKMapViewDelegate {
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
    
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let roadPolyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: roadPolyline)
            renderer.strokeColor = colors[roadPolyline]
            renderer.lineWidth = 1
            return renderer
        }
        if let imageOverlay = overlay as? ImageOverlay {
            let renderer = ImageOverlayRenderer(overlay: imageOverlay)
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        myMap.region = mapView.region
    }
    
    //https://www.youtube.com/watch?v=DHpL8yz6ot0
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        if let lightAnn = annotation as? LightAnnotation {
            let annView = mapView.dequeueReusableAnnotationView(withIdentifier: lightAnn.id) ?? MKAnnotationView(annotation: annotation, reuseIdentifier: lightAnn.id)
            // the constructor is not evaluated unless the optional is nil - I tested this in REPL - the second expression is not evaluated and cached, for example.
            annView.addSubview(UIHostingController(rootView: LightView()).view)
            return annView
        }
        
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "car") ?? MKAnnotationView(annotation: annotation, reuseIdentifier: "car")
        annotationView.image = UIImage(named: "Car")
        return annotationView
    }
}

// MARK: Previews

let jobsTheater = CLLocationCoordinate2D(latitude: 37.330828, longitude: -122.007495)
let cafeMacs = CLLocationCoordinate2D(latitude: 37.336083, longitude: -122.007356)
let appleWellness = CLLocationCoordinate2D(latitude: 37.336901, longitude:  -122.012345)

struct MapView_Previews: PreviewProvider {
    struct MapView_PreviewProvider: View {
        @State private var region = MKCoordinateRegion(
            // Apple Park
            center: CLLocationCoordinate2D(latitude: 37.334803, longitude: -122.008965),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        private var polyline = ColorPolyline(polyline: MKPolyline(coordinates: [
            jobsTheater,
            cafeMacs,
            appleWellness
        ], count: 3), color: UIColor.systemGreen)
        
        var body: some View {
            MapView(
                region: $region,
                mapType: .constant(.satellite),
                overlays: .constant([
                    ImageOverlay(
                        image: carImage,
                        coordinate: jobsTheater,
                        direction: 30,
                        widthFeet: teslaLength,
                        heightFeet: teslaLength
                    )]),
                polylines: [polyline],
                annotations: Binding<[MKAnnotation]>.constant([MKAnnotation]())
            )
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    static var previews: some View {
        MapView_PreviewProvider()
    }
}
