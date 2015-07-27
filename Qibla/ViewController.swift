//
//  Qibla.swift
//
//  Created by Amin Benarieb on 26/07/15.
//  Copyright (c) 2015 Amin Benarieb. All rights reserved.
//

import UIKit
import CoreLocation

// MARK: - Constants
let accurency = 10.0 // as degree
let lattituteOfMecca = 21.42247
let longtitueOfMecca = 39.826207
let shouldDisplayHeadingCalibration = true

let DarkGrayColor = 0x535353
let GreenColor = 0x347B3D

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}

class Qibla: UIViewController, CLLocationManagerDelegate {
    
    // MARK: - Properties
    var locationManager: CLLocationManager!
    var currentLocation : CLLocation?
    var askForAuthorizationIfNeeded = true
    
    @IBOutlet var compas_arrow : UIImageView!
    @IBOutlet var compas_bg    : UIImageView!
    @IBOutlet var label        : UILabel!
    @IBOutlet var label_degree : UILabel!
    @IBOutlet var label_hint   : UILabel!
    
    // MARK: - View Events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.activityType = CLActivityType.Other
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.distanceFilter = 1000.0
        
        self.tryStartUpdating()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        label_hint.text = "Turn you device to arrow's direction. It would a direction to Qibla."
        self.title = "Qibla Compass"
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager!, didUpdateHeading newHeading: CLHeading!) {
        
        if let magneticHeading = newHeading?.trueHeading //degrees
        {
            if let coordinate = self.currentLocation?.coordinate
            {
                let currentAngle = Double(magneticHeading)
                
                if let angleOfQibla = angleOfQiblaClockwiseFromTrueNorth(coordinate.latitude, lon: coordinate.longitude)
                {
                    
                    var rotationInDegree = currentAngle - angleOfQibla
                    
                    label_degree.text = "\(Int(rotationInDegree))˚"
                    
                    self.label.text = ("Angle of qibla: \(angleOfQibla),\n current angle: \(currentAngle)\n degree to rotate \(rotationInDegree)\n accuracy: \(newHeading.headingAccuracy)")

                    rotationInDegree = fmod((rotationInDegree + 360), 360);  //just to be on the safe side :-)
                    
                    if fabs(currentAngle - angleOfQibla) <= accurency
                    {
                        self.compas_arrow.image = UIImage(named: "compas_arrow_right")
                        self.compas_bg.image = UIImage(named: "compas_bg_right")
                        self.label_degree.textColor = UIColor(netHex: GreenColor)
                    }
                    else
                    {
                        self.compas_arrow.image = UIImage(named: "compas_arrow")
                        self.compas_bg.image = UIImage(named: "compas_bg")
                        self.label_degree.textColor = UIColor(netHex: DarkGrayColor)
                    }
                    
                    
                    self.compas_arrow.transform = CGAffineTransformMakeRotation( CGFloat( (angleOfQibla-newHeading.trueHeading) * M_PI / 180) );
                }
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        self.tryStartUpdating()
    }
    
    func locationManagerShouldDisplayHeadingCalibration(manager: CLLocationManager!) -> Bool {
        return shouldDisplayHeadingCalibration
    }
    
    // MARK: - Functions
    
    func isLocationServiceAuthorized() -> Bool{
        
        if CLLocationManager.locationServicesEnabled() == false {
            return false // globally disabled.
        }
        
        var status : Bool
        switch CLLocationManager.authorizationStatus() {
            
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            status = true
            break;
            
        case .Denied, .Restricted, .NotDetermined:
            status = false
            break;
        }
        
        return status
    }
    
    func tryStartUpdating()
    {
        if isLocationServiceAuthorized(){
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            self.currentLocation = locationManager.location
        }
        else {
            if self.askForAuthorizationIfNeeded && locationManager.respondsToSelector(Selector("requestWhenInUseAuthorization")) {
                locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    func angleOfQiblaClockwiseFromTrueNorth(lat: Double, lon: Double) -> Double?{
        
        if abs(lat - lattituteOfMecca) < abs(0.01) && abs(lon - longtitueOfMecca) < abs(0.01){
            // Already in Mecca
            return nil
        }
        
        let phiK = lattituteOfMecca * M_PI / 180.0
        let lambdaK = longtitueOfMecca * M_PI / 180.0
        let phi = lat * M_PI / 180.0
        let lambda = lon * M_PI / 180.0
        
        let psi = round(180.0 / M_PI * atan2( sin(lambdaK-lambda), cos(phi) * tan(phiK) - sin(phi) * cos(lambdaK-lambda)))
        
        let degree : Double
        
        if psi < 0
        {
            degree = 360.0 - abs(psi)
        }
        else
        {
            degree = psi
        }
        
        return degree
    }
    
}