//
//  MainViewController.swift
//  geofence
//
//  Created by Modo Ltunzher on 1/3/19.
//  Copyright © 2019 Modo Ltunzher. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
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

    private var viewLifeDisposeBag: DisposeBag!
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
            self.viewLifeDisposeBag = nil
            self.view = nil
        }
    }
    
// MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewLifeDisposeBag = DisposeBag()

        // Summary
        let observableIsMonitoring = self.locationService.isMonitoringObservable
        let observableRegionState = self.locationService.regionStateObservable
        Observable.combineLatest(observableIsMonitoring, observableRegionState)
            .subscribe(onNext: { [weak self] _, _ in
                let indexPath = IndexPath(row: Row.summary.rawValue, section: 0)
                self?.tableView?.reloadRows(at: [indexPath], with: .automatic)
            }).disposed(by: self.viewLifeDisposeBag)

        // Location services status
        let observableStatus = self.locationService.serviceAuthorizationStatusObservable
        let observableIsEnabled = self.locationService.serviceIsEnabledObservable
        Observable.combineLatest(observableStatus, observableIsEnabled)
            .subscribe(onNext: { [weak self] _, _ in
                let indexPath = IndexPath(row: Row.locationStatus.rawValue, section: 0)
                self?.tableView?.reloadRows(at: [indexPath], with: .automatic)
            }).disposed(by: self.viewLifeDisposeBag)
        
        // Geofence region
        let observableCenter = self.locationService.geofenceCenter.asObservable()
        let observableRadius = self.locationService.geofenceRadius.asObservable()
        Observable.combineLatest(observableCenter, observableRadius)
            .subscribe(onNext: { [weak self] _, _ in
                let indexPaths = [
                    IndexPath(row: Row.coordinate.rawValue, section: 0),
                    IndexPath(row: Row.radius.rawValue, section: 0)
                ]
                self?.tableView?.reloadRows(at: indexPaths, with: .automatic)
            }).disposed(by: self.viewLifeDisposeBag)
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
        guard self.locationService.serviceAuthorizationStatus == .notDetermined else {
            let alert = UIAlertController(title: "Location Services", message: "Current status: \(self.locationService.serviceAuthorizationStatus.humanReadableDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { [weak self] _ in
                self?.openApplictionSettins()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        self.locationService.requestAlwaysAuthorization()
    }
    
    private func pickLocation(forcePick: Bool = false) {
        guard forcePick || self.locationService.geofenceCenter.value == nil else {
            let actionSheet = UIAlertController(title: "Geofence center", message: "Change", preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            actionSheet.addAction(UIAlertAction(title: "Remove Region", style: .destructive, handler: { _ in
                self.locationService.geofenceCenter.value = nil
            }))
            actionSheet.addAction(UIAlertAction(title: "Select New Center", style: .default, handler: { _ in
                self.pickLocation(forcePick: true)
            }))
            self.present(actionSheet, animated: true, completion: nil)
            return
        }
        let pickerVc = LocationPicker()
        pickerVc.pickCompletion = { [weak self] (item) in
            if let (lat, lon) = item.coordinate {
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                self?.updateGeofenceCenter(coordinate)
            } else {
                self?.updateGeofenceCenter(nil)
            }
        }
        self.navigationController?.pushViewController(pickerVc, animated: true)
    }
    
    private func updateGeofenceCenter(_ center: CLLocationCoordinate2D?) {
        self.locationService.geofenceCenter.value = center
    }
    
    private func inputRadius() {
        let alert = UIAlertController(title: "Geofence Radius", message: "in meters", preferredStyle: .alert)
        let actionOk = UIAlertAction(title: "OK", style: .default) { [weak alert, weak self] _ in
            guard let numberString = alert?.textFields?.first?.text,
                let number = Double(numberString),
                number > 0 else {
                return
            }
            self?.locationService.geofenceRadius.value = number
        }
        
        alert.addTextField { textField in
            textField.rx.text.orEmpty
                .map { (Double($0) ?? 0) > 0 }
                .share(replay: 1)
                .bind(to: actionOk.rx.isEnabled)
                .disposed(by: self.viewLifeDisposeBag)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(actionOk)
        self.present(alert, animated: true, completion: nil)
    }

// MARK: - Private (Cells)
    
    private func setupCellLocationStatus(_ cell: UITableViewCell) {
        let statusString = "Location service access status: \(self.locationService.serviceAuthorizationStatus.humanReadableDescription)"
        let serviceIsEnabledString = "Service is enabled: \(self.locationService.serviceIsEnabled)"
        cell.textLabel?.text = statusString
        cell.detailTextLabel?.text = serviceIsEnabledString
    }
    
    private func setupCellCoordinate(_ cell: UITableViewCell) {
        if let loc = self.locationService.geofenceCenter.value {
            cell.textLabel?.text = "Change Coordinate"
            let lat = String(format: "%.4f", loc.latitude)
            let lon = String(format: "%.4f", loc.longitude)
            cell.detailTextLabel?.text = "Coordinate: lat \(lat) lon \(lon)"
        } else {
            cell.textLabel?.text = "Select Coordinate"
            cell.detailTextLabel?.text = nil
        }
    }
    
    private func setupCellRadius(_ cell: UITableViewCell) {
        cell.textLabel?.text = "Radius"
        let radius = self.locationService.geofenceRadius.value
        cell.detailTextLabel?.text = radius > 0
            ? "\(self.locationService.geofenceRadius.value) meters"
            : "not set"
    }
    
    private func setupCellSummary(_ cell: UITableViewCell) {
        var summary: String = "Region monitoring: "
        summary += self.locationService.isMonitoring
            ? "active"
            : "off"
        summary += "\n"
        summary += "Region status: \(self.locationService.regionState?.humanReadableDescription ?? "no information")"
        cell.textLabel?.text = summary
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
