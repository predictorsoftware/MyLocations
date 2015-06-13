//
//  CurrentLocationViewController.swift
//  MyLocations
//
//  Created by Gru on 06/12/15.
//  Copyright (c) 2015 GruTech. All rights reserved.
//

import UIKit

class CurrentLocationViewController: UIViewController {

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!

    @IBOutlet weak var getButton: UIButton!
    
    @IBAction func getLocation() {

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

