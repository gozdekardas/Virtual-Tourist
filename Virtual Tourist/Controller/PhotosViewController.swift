//
//  PhotosViewController.swift
//  Virtual Tourist
//
//  Created by GOZDE KARDAS on 8.06.2021.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotosViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollection: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var pin: Pin!
    var fetchedResultsController: NSFetchedResultsController<PhotoFlickr>!
        var photosURL: [PhotoResponse] = []
        var flckrPhotos = [PhotoFlickr]()
    var blockOperations: [BlockOperation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        setupFetchedResultsController()
        setupMapView()
        setupAlbum()
        //FlickrClient.flickrGETSearchPhotos(lat: pin.latitude, lon: pin.longitude, completionHandler: getFlickrImagesURL(photos:error:))
    }
    
    fileprivate func setupAlbum() {
            if !checkPinHasAlbum() {
                FlickrClient.flickrGETSearchPhotos(lat: pin.latitude, lon: pin.longitude, completionHandler: getFlickrImagesURL(photos:error:))
            }else{
                if let objects = fetchedResultsController.fetchedObjects{
                    flckrPhotos = objects
                }
            }
        }
    
    func checkPinHasAlbum() -> Bool {
            if let photosFetched = fetchedResultsController.fetchedObjects{
                if !photosFetched.isEmpty{
                    return true
                }
            }
            return false
        }
    
    fileprivate func setupFetchedResultsController() {
            let fetchRequest: NSFetchRequest<PhotoFlickr> = PhotoFlickr.fetchRequest()
            
            let predicate = NSPredicate(format: "pin == %@", pin)
            fetchRequest.predicate = predicate
            
            fetchRequest.sortDescriptors = []
            
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            
            fetchedResultsController.delegate = self
        
            try? fetchedResultsController.performFetch()
        }
    
    func setupMapView(){
        
        mapView.delegate = self
        
        var annotations = [MKPointAnnotation]()
        
        let lat = CLLocationDegrees(pin.latitude)
        let long = CLLocationDegrees(pin.longitude)
        
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        annotations.append(annotation)
        
        self.mapView.addAnnotations(annotations)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
    }
    
    func getFlickrImagesURL(photos: [PhotoResponse], error: Error?){
            print(photos.count)
            if error == nil {
                if photos.count != 0 {
                    for photo in photos {
                        if photo.imageURL != nil {
                            let image = PhotoFlickr(context: DataController.shared.viewContext)
                            image.pin = self.pin
                            flckrPhotos.append(image)
                            self.photosURL.append(photo)
                            print(flckrPhotos.count)
                        }
                    }
                } else {
                    self.newCollection.isEnabled = true
                }
            }
            self.collectionView.reloadData()
        }
    
    fileprivate func setupCollectionView() {
           //   collectionView.delegate = self
           //   collectionView.dataSource = self
              setCollectionFlowLayout()
          }
    
    func setCollectionFlowLayout() {
            
            let items: CGFloat = view.frame.size.width > view.frame.size.height ? 5.0 : 3.0
            let space: CGFloat = 1.0
            let dimension = (view.frame.size.width - ((items + 1) * space)) / items
            
            let layout = UICollectionViewFlowLayout()
            layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            layout.minimumLineSpacing = 8.0 - items
            layout.minimumInteritemSpacing = space
            layout.itemSize = CGSize(width: dimension, height: dimension)
            
            collectionView.collectionViewLayout = layout
        }
    
    @IBAction func newCollection(_ sender: Any) {
        flckrPhotos = []
               photosURL = []
               newCollection.isEnabled = false
           
               if let  objects = fetchedResultsController.fetchedObjects{
                   for object in objects{
                       DataController.shared.viewContext.delete(object)
                   }
                   DataController.shared.saveViewContext()
                   FlickrClient.flickrGETSearchPhotos(lat: pin.latitude, lon: pin.longitude, completionHandler: getFlickrImagesURL(photos:error:))
               }
    }
    
}

extension PhotosViewController: MKMapViewDelegate{
    
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
    
}


extension PhotosViewController: NSFetchedResultsControllerDelegate{
        
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if type == NSFetchedResultsChangeType.insert {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItems(at: [newIndexPath!])
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.update {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItems(at: [indexPath!])
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.move {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItem(at: indexPath!, to: newIndexPath!)
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.delete {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItems(at: [indexPath!])
                    }
                })
            )
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        if type == NSFetchedResultsChangeType.insert {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertSections(NSIndexSet(index: sectionIndex) as IndexSet)
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.update {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadSections(NSIndexSet(index: sectionIndex) as IndexSet)
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.delete {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet)
                    }
                })
            )
        }
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView!.performBatchUpdates({ () -> Void in
                for operation: BlockOperation in self.blockOperations {
                    operation.start()
                }
            }, completion: { (finished) -> Void in
                self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
}


extension PhotosViewController: UICollectionViewDelegate, UICollectionViewDataSource{
        
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return flckrPhotos.count
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
           
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
                print(indexPath)
            if flckrPhotos[indexPath.row].image != nil {
                cell.imageView.image = UIImage(data: flckrPhotos[indexPath.row].image!)
            } else {
                DispatchQueue.global().async {
                    FlickrClient.downloadImage(imageURL: URL(string: self.photosURL[indexPath.row].imageURL!)!) { (data, error) in
                            if let data = data {
                                cell.imageView.image = UIImage(data: data)
                                self.flckrPhotos[indexPath.row].image = data
                                DataController.shared.saveViewContext()
                                if self.fetchedResultsController.fetchedObjects?.count == self.flckrPhotos.count{
                                    self.newCollection.isEnabled = true
                                }
                            }
                        }
                    }
                }
                return cell
        }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let objectToDelete = fetchedResultsController.object(at: indexPath)
        flckrPhotos.remove(at: indexPath.row)
        DataController.shared.viewContext.delete(objectToDelete)
        DataController.shared.saveViewContext()
    }
}
