//
//  MainViewController.swift
//  geofence
//
//  Created by Modo Ltunzher on 1/3/19.
//  Copyright © 2019 Modo Ltunzher. All rights reserved.
//

import UIKit
import LocationPickerViewController
import CoreLocation
import CoreGeoFence

class MainViewController: UITableViewController {

// MARK: Publics

// MARK: Privates

    private enum Row: Int, CaseIterable {
        case summary
        case locationStatus
        case coordinate
        case radius
    }
    private let defaultCellId = "defaultCellId"
    private let locationService: LocationService
    
// MARK: - Memory Management

    init(locationService: LocationService) {
        self.locationService = locationService
        super.init(style: .grouped)
        self.title = "Geofence"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        if self.viewIfLoaded?.window == nil {
            self.view = nil
        }
    }
    
// MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
// MARK: - Action Handlers

// MARK: - Public

// MARK: - Private

    private func openApplictionSettins() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(url) else {
            return
        }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    private func checkRequestLocationPermission() {
        self.locationService.requestAlwaysAuthorization()
    }
    
    private func pickLocation(forcePick: Bool = false) {
        // TODO
    }
    
    private func inputRadius() {
        // TODO
    }

// MARK: - Private (Cells)
    
    private func setupCellLocationStatus(_ cell: UITableViewCell) {
        let statusString = "Location service access status"
        cell.textLabel?.text = statusString
    }
    
    private func setupCellCoordinate(_ cell: UITableViewCell) {
        cell.textLabel?.text = "Select Coordinate"
    }
    
    private func setupCellRadius(_ cell: UITableViewCell) {
        cell.textLabel?.text = "Radius"
    }
    
    private func setupCellSummary(_ cell: UITableViewCell) {
        cell.textLabel?.text = "Summary here"
    }

// MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let row = Row(rawValue: indexPath.row) else { return }
        
        switch row {
        case .locationStatus:
            self.checkRequestLocationPermission()
        case .coordinate:
            self.pickLocation()
        case .radius:
            self.inputRadius()
        case .summary:
            ()
        }
    }    

// MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Row.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.defaultCellId)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: self.defaultCellId)
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil

        if let row = Row(rawValue: indexPath.row) {
            switch row {
            case .locationStatus:
                self.setupCellLocationStatus(cell)
            case .coordinate:
                self.setupCellCoordinate(cell)
            case .radius:
                self.setupCellRadius(cell)
            case .summary:
                self.setupCellSummary(cell)
            }
        }
        return cell
    }

}
