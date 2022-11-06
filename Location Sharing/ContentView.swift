//
//  ContentView.swift
//  Location Sharing
//
//  Created by Hoa Truong on 11/5/22.
//

import SwiftUI
import Firebase
import CoreLocation
import MapKit

struct ContentView: View {
    
    @State var name = ""
    @ObservedObject var obs = observer()
    
    var body: some View {
        NavigationView{
            
            VStack{
                TextField("Enter Name", text: $name).textFieldStyle(RoundedBorderTextFieldStyle())
                
                if name != ""{
                    
                    NavigationLink(destination: mapView(name: self.name, geopoints: self.obs.data["data"] as! [String : GeoPoint]).navigationBarTitle("", displayMode: .inline)){
                        
                        Text("Share Location")
                    }
                }
                
            }.padding()
            .navigationBarTitle("Location sharing")
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct mapView : UIViewRepresentable {
    
    var name = ""
    var geopoints : [String : GeoPoint]
    
    func makeCoordinator() -> Coordinator {
        return mapView.Coordinator(parent1: self)
    }
    
    let map = MKMapView()
    let manager = CLLocationManager()
    
    
    func makeUIView(context: UIViewRepresentableContext<mapView>) -> MKMapView {
        
        manager.delegate = context.coordinator
        manager.startUpdatingLocation()
        map.showsUserLocation = true
        // have the location center
        let center = CLLocationCoordinate2D(latitude: 13.086, longitude: 80.2707)
        // zoom in the location
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 1000, longitudinalMeters: 1000)
        map.region = region
        manager.requestWhenInUseAuthorization()
        return map
    }
    
    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<mapView>) {
        
        for i in geopoints{

            if i.key != name {
                // add the red point on the location => need to fix only see 2 locations at a time
                let point = MKPointAnnotation()
                point.coordinate = CLLocationCoordinate2D(latitude: i.value.latitude, longitude: i.value.longitude)
                point.title = i.key
                uiView.removeAnnotations(uiView.annotations)
                uiView.addAnnotation(point)
            }
        }
        
    }
    
    class Coordinator: NSObject, CLLocationManagerDelegate {
        
        var parent: mapView
        
        init(parent1 : mapView) {
            parent = parent1
        }
        
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            
            if status == .denied{
                print("denied")
            }
            if status == .authorizedWhenInUse{
                print("authorized")
            }
        }
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            let last = locations.last
    
            let db = Firestore.firestore()
            
            db.collection("locations").document("sharing").setData(["updates":[self.parent.name : GeoPoint(latitude: (last?.coordinate.latitude)!, longitude: (last?.coordinate.longitude)!)]], merge: true) {(err) in
                
                if err != nil {
                    print((err?.localizedDescription)!)
                    return
                }
                print("success")
            }
        }
    }
}
                                                                            
class observer : ObservableObject {
    
    @Published var data = [String : Any]()
    
    init() {
        
        let db = Firestore.firestore()
        
        db.collection("locations").document("sharing").addSnapshotListener { (snap, err)
            in
            
            if err != nil {
                print((err?.localizedDescription))
                return
            }
            
            let updates = snap?.get("updates") as! [String : GeoPoint]
            
            self.data["data"] = updates
        }
    }
}
                                                                            
