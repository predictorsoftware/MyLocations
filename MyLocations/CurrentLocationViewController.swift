//
//  CurrentLocationViewController.swift
//  MyLocations
//
//  Created by Gru on 06/12/15.
//  Copyright (c) 2015 GruTech. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var messageLabel:   UILabel!
    @IBOutlet weak var latitudeLabel:  UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel:   UILabel!
    @IBOutlet weak var tagButton:      UIButton!

    @IBOutlet weak var getButton:      UIButton!

    // 'CLLocationManager' is where the GPS coordinates come from.
    let locationManager     = CLLocationManager()
    var location: CLLocation?
    var updatingLocation    = false                                             // p.394
    var lastLocationError: NSError?

    let geocoder                    = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding  = false
    var lastGeocodingError: NSError?
    var timer: NSTimer?

    func updateLabels() {
        if let location = location {
            latitudeLabel.text    = String( format: "%.8f", location.coordinate.latitude )
            longitudeLabel.text   = String( format: "%.8f", location.coordinate.longitude )
            tagButton.hidden      = false
            messageLabel.text     = ""
            if let placemark = placemark {
                addressLabel.text = stringFromPlacemark(placemark)
            } else if performingReverseGeocoding {
                addressLabel.text = "Searching for Address..."
            } else if lastGeocodingError != nil {
                addressLabel.text = "Error Finding Address"
            } else {
                addressLabel.text = "No Address Found"
            }
        } else {
            latitudeLabel.text  = ""
            longitudeLabel.text = ""
            addressLabel.text   = ""
            tagButton.hidden    = true

            // The new code starts here, p.396
            var statusMessage: String
            if let error = lastLocationError {
                if error.domain == kCLErrorDomain && error.code == CLError.Denied.rawValue {
                    statusMessage = "Location Services Disabled"
                } else {
                    statusMessage = "Error Getting Location"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage     = "Location Services Disabled"
            } else if updatingLocation {
                statusMessage     = "Searching..."
            } else {
                statusMessage     = "Tap 'Get My Location' to Start"
            }
            messageLabel.text     = statusMessage
        }
    }

    // Placemark:
    //  subThoroughfare    - house number
    //  thoroughface       - street name
    //  locality           - city
    //  administrativeArea - state or province
    //  postalCode         - zip code or postal code
    func stringFromPlacemark( placemark: CLPlacemark ) -> String {              // p.407
        return "\(placemark.subThoroughfare) \(placemark.thoroughfare) \n" +
               "\(placemark.locality) \(placemark.administrativeArea) \(placemark.postalCode)"
    }

    func startLocationManager() {                                               // p.397
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation         = true

            timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: Selector( "didTimeOut"), userInfo: nil, repeats: false )
        }
    }

    func stopLocationManager() {                                                // p.396
        if updatingLocation {
            if let timer = timer {
                timer.invalidate()
            }
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation         = false
        }
    }

    func didTimeOut() {                                                         // p.412
        println( "*** Time Out! ***" )
        if location == nil {
            stopLocationManager()
            lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil )
            updateLabels()
            configureGetButton()
        }
    }

    @IBAction func getLocation() {

        let authStatus: CLAuthorizationStatus = CLLocationManager.authorizationStatus()

        if authStatus == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        if authStatus == .Denied || authStatus == .Restricted {
            showLocationServicesDeniedAlert()
            return
        }
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
//        locationManager.startUpdatingLocation()
//        startLocationManager()
        if updatingLocation {                                                   // p.402
            stopLocationManager()
        } else {
            location            = nil
            lastLocationError   = nil
            placemark           = nil
            lastGeocodingError  = nil
            startLocationManager()

        }
        updateLabels()
        configureGetButton()                                                    // p.401
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        configureGetButton()                                                    // p.401
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // Function: configureGetButton()
    //
    // If the app is currently updating the location then the button's title
    // becomes 'Stop', otherwise it is 'Get My Location'.
    func configureGetButton() {
        if updatingLocation {
            getButton.setTitle( "Stop", forState: .Normal )
        } else {
            getButton.setTitle( "Get My Location", forState: .Normal )
        }
    }

//  MARK: - CLLocationManagerDelegate

    func locationManager( manager: CLLocationManager!, didFailWithError error: NSError! ) {
        println( "didFailWithError \(error)" )

        if error.code == CLError.LocationUnknown.rawValue {                     // p.395
            return
        }
        lastLocationError = error
        stopLocationManager()
        updateLabels()
        configureGetButton()                                                    // p.402
    }

    //   locationManager - didUpdateLocations, p.399
    func locationManager( manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]! ) {

        var distance    = CLLocationDistance(DBL_MAX)

        let newLocation = locations.last as! CLLocation
        println( "didUpdateLocation \(newLocation)" )

        // 1
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        // 2
        if newLocation.horizontalAccuracy < 0 {
            return
        }

        if let location = location {                                            // p.410
            distance = newLocation.distanceFromLocation( location )
        }

        // 3
        if location == nil  ||  location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            // 4
            lastLocationError   = nil
            location            = newLocation
            updateLabels()
            // 5
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
                println( "*** We're done! ***" )
                stopLocationManager()
                configureGetButton()                                            // p.402
            }

            if distance > 0 {                                                   // p.410
                performingReverseGeocoding = false
            }

            if !performingReverseGeocoding {
                println( "*** Going to geocode ***" )

                performingReverseGeocoding = true

                // Tell the 'CLGeoCoder' object that you want to reverse geocode the location,
                // and that the code in the clock following completionHandler: should
                // be executed as soon as the geocoding is completed.  (Closure) p.405
                geocoder.reverseGeocodeLocation( location, completionHandler: {
                    placemarks, error in println( "*** Found placemarks: \(placemarks), error: \(error) ***")
                                         self.lastLocationError = error         // p.406
                                         if error == nil  &&  !placemarks.isEmpty {
                                            // Lets 'type cast' the object that is retrieved from
                                            // the array to CLPlacemark, using the 'as' operator:
                                            self.placemark = placemarks.last as? CLPlacemark
                                         } else {
                                            self.placemark = nil
                                         }
                                         self.performingReverseGeocoding = false
                                         self.updateLabels()
                    })
            }
        } else if distance   < 1.0 {   // 1.0 meter
            let timeInterval = newLocation.timestamp.timeIntervalSinceDate( location!.timestamp )
            if timeInterval  > 10  {   // 10.0 meter
                println( "*** Force Done! ***" )
                stopLocationManager()
                updateLabels()
                configureGetButton()
            }
        }
        // End of the new code on p.404
//        lastLocationError = nil     // Clear last error meassage...                p.398
//        location          = newLocation
//        updateLabels()

    }



    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController( title: "Location Services Disabled",
                                     message: "Please enable location services for this app in Settings,",
                              preferredStyle: .Alert )
        let okAction = UIAlertAction( title: "OK", style: .Default, handler: nil )
        alert.addAction( okAction )

        presentViewController( alert, animated: true, completion: nil )
    }
}


