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
import UIKit

struct ContentView: View {
    
    @State var name = ""
    @ObservedObject var obs = observer()
    @State var searchText = ""
    
    var body: some View {
        NavigationView{
            
            VStack{
                TextField("Enter Name", text: $name).textFieldStyle(RoundedBorderTextFieldStyle())
                
                if name != ""{
                    
                    NavigationLink(destination: mapView(name: self.name, geopoints: self.obs.data["data"] as! [String : GeoPoint]).searchable(text: $searchText).navigationBarTitle("", displayMode: .inline)){
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
    var locationManager = CLLocationManager()
    

    
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
        guard let coordinate = locationManager.location?.coordinate else {return map}
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        map.region = coordinateRegion
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<mapView>) {
        var fullAdress = ""
        
        for i in geopoints{
            if i.key != name {
                // add the red point on the location => need to fix only see 2 locations at a time
                let point = MKPointAnnotation()
                point.coordinate = CLLocationCoordinate2D(latitude: i.value.latitude, longitude: i.value.longitude)
                uiView.addAnnotation(point)
                
                let geoCoder = CLGeocoder()
                
                let location = CLLocation(latitude: i.value.latitude, longitude: i.value.longitude)
                geoCoder.reverseGeocodeLocation(location, completionHandler:
                    {
                        placemarks, error -> Void in
                        // Place details
                        guard let placeMark = placemarks?.first else { return }

                        // Location name
                    if let locationName = placeMark.location {
                        var LocationName = String(format:"@", locationName)
                        }
                    // Street address
                    if let street = placeMark.thoroughfare {
                        var Street = String(format: "%@", street)
                        fullAdress += Street
                        fullAdress += ", "
                    }
                    // City
                    if let city = placeMark.subAdministrativeArea {
                        var City = String(format: "%@", city)
                        fullAdress += City
                        fullAdress += ", "
                    }
                    // Zip code
                    if let zip = placeMark.isoCountryCode {
                        var Zip = String(format: "%@", zip)
                        fullAdress += Zip
                        fullAdress += ", "
                    }
                    // Country
                    if let country = placeMark.country {
                        var Country = String(format: "%@", country)
                        fullAdress += Country
                        fullAdress += ", "
                    }
                    //
                    point.title = i.key + ": " + fullAdress
                    fullAdress = ""
                })
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
                                                                            
