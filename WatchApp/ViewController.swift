//
//  ViewController.swift
//  WatchApp
//
//  Created by Akshay Khandizod on 27/12/24.
//


import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Example data
        let stepCount = 1000
        let heartRate = 72.5

        // Store data in shared user defaults
        if let groupUserDefaults = UserDefaults(suiteName: "group.com.example.HealthData") {
            groupUserDefaults.set(stepCount, forKey: "stepCount")
            groupUserDefaults.set(heartRate, forKey: "heartRate")
            print(stepCount)
            print( heartRate)
        } else {
            print("Failed to access shared user defaults")
        }
    }
}
