//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by GOZDE KARDAS on 7.06.2021.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, NSFetchedResultsControllerDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController:DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFetchedResultsController()
        setupMapView()
    }
    
    
    @objc func handleTapGesture(_ gestureRecognizer: UILongPressGestureRecognizer){
        
        if gestureRecognizer.state != .began { return }
        
        let location = gestureRecognizer.location(in: self.mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: self.mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        mapView.setCenter(mapView.centerCoordinate, animated: true)
        
        let pin = Pin(context: DataController.shared.viewContext)
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        
        DataController.shared.saveViewContext()
        try? fetchedResultsController.performFetch()
        
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func setupMapView() {
        self.mapView.delegate = self
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        mapView.addGestureRecognizer(gestureRecognizer)
        mapView.isRotateEnabled = false
        gestureRecognizer.delegate = self
        
        if let region = getMapRegion(), let pins = fetchedResultsController.fetchedObjects {
            mapView.setRegion(region, animated: true)
            generateAnnotations(pins)
        }
    }
    
    func getMapRegion() -> MKCoordinateRegion? {
        if let userMapRegion = UserDefaults.standard.dictionary(forKey: "userMapRegion"){
            let userCenter = CLLocationCoordinate2D(latitude: userMapRegion["latitude"] as! CLLocationDegrees, longitude: userMapRegion["longitude"] as! CLLocationDegrees)
            let userSpan = MKCoordinateSpan(latitudeDelta: userMapRegion["delta_latitude"] as! CLLocationDegrees, longitudeDelta: userMapRegion["delta_longitude"] as! CLLocationDegrees)
            return MKCoordinateRegion(center: userCenter, span: userSpan)
        }
        return nil
    }
    
    func generateAnnotations(_ pins: [Pin]){
        
        var annotations = [MKPointAnnotation]()
        
        for pin in pins {
            
            let lat = CLLocationDegrees(pin.latitude)
            let long = CLLocationDegrees(pin.longitude)
            
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            annotations.append(annotation)
        }
        self.mapView.addAnnotations(annotations)
    }
    
    func saveUserRegion(_ mapRegion: MKCoordinateRegion?){
        if let mapRegion = mapRegion {
            let userMapRegion = ["latitude": mapRegion.center.latitude,
                                 "longitude": mapRegion.center.longitude,
                                 "delta_latitude": mapRegion.span.latitudeDelta,
                                 "delta_longitude": mapRegion.span.longitudeDelta]
            UserDefaults.standard.set(userMapRegion, forKey: "userMapRegion")
        }
    }
    
    
}

extension MapViewController: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil{
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .blue
            
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveUserRegion(mapView.region)
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        let photosViewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
        
        if let selectedPinLat = view.annotation?.coordinate.latitude,
           let selectedPinLon = view.annotation?.coordinate.longitude, let pins = fetchedResultsController.fetchedObjects{
            for pin in pins{
                if pin.latitude == selectedPinLat && pin.longitude == selectedPinLon{
                    print(pin.latitude)
                    print(pin.longitude)
                    photosViewController.pin = pin
                }
            }
            self.navigationController?.pushViewController(photosViewController, animated: true)
        }
    }
    
    
}


