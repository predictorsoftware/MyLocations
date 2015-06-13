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
            location          = nil
            lastLocationError = nil
            startLocationManager()
        }
        updateLabels()
        configureGetButton()                                                    // p.401
    }

    // 'CLLocationManager' is where the GPS coordinates come from.
    let locationManager     = CLLocationManager()
    var location: CLLocation?
    var updatingLocation    = false                                             // p.394
    var lastLocationError: NSError?


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
        // 3
        if location == nil ||  location!.horizontalAccuracy > newLocation.horizontalAccuracy {
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
        }

        lastLocationError = nil     // Clear last error meassage...                p.398
        location          = newLocation
        updateLabels()
    }

    func startLocationManager() {                                               // p.397
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation         = true
        }
    }

    func stopLocationManager() {                                                // p.396
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation         = false
        }
    }

    func updateLabels() {
        if let location = location {
            latitudeLabel.text  = String( format: "%.8f", location.coordinate.latitude )
            longitudeLabel.text = String( format: "%.8f", location.coordinate.longitude )
            tagButton.hidden    = false
            messageLabel.text   = ""
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

    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController( title: "Location Services Disabled",
                                     message: "Please enable location services for this app in Settings,",
                              preferredStyle: .Alert )
        let okAction = UIAlertAction( title: "OK", style: .Default, handler: nil )
        alert.addAction( okAction )

        presentViewController( alert, animated: true, completion: nil )
    }
}


