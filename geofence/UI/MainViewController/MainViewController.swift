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
        case notifications
    }
    private let defaultCellId = "defaultCellId"
    private let defaultNotifiationId = "defaultNotifiationId"

    private var disposeBag = DisposeBag()
    private var viewLifeDisposeBag: DisposeBag!
    private let locationService: LocationService
    private let notificationService: NotificationService

// MARK: - Memory Management

    init(locationService: LocationService, notificationService: NotificationService) {
        self.locationService = locationService
        self.notificationService = notificationService
        super.init(style: .grouped)
        self.title = "Geofence"
        
        // Notification
        self.locationService.regionStateObservable.subscribe(onNext: { [weak self] (state) in
            guard let state = state else { return }
            self?.sendNotification(for: state)
        }).disposed(by: self.disposeBag)

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
    }
    
// MARK: - Action Handlers

// MARK: - Public

// MARK: - Private

    private func sendNotification(for state: CLRegionState) {
        let message = "New region state: \(state.humanReadableDescription)"
        self.notificationService.sendNotification(message, identifier: self.defaultNotifiationId)
    }
    
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

    private func checkRequestNotificationPermissions() {
        self.notificationService.requestNotificationsAuthorization()
    }
    
// MARK: - Private (Cells)
    
    private func setupCellLocationStatus(_ cell: DisposableTableViewCell) {
        self.locationService.serviceAuthorizationStatusObservable
            .map {
                "Location service access status \($0.humanReadableDescription)"
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak cell] title in
                cell?.textLabel?.text = title
            })
            .disposed(by: cell.disposableOnReuse)
        
        self.locationService.serviceIsEnabledObservable
            .map {
                 "Service is enabled: \($0)"
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak cell] title in
                cell?.detailTextLabel?.text = title
            })
            .disposed(by: cell.disposableOnReuse)
    }
    
    private func setupCellCoordinate(_ cell: DisposableTableViewCell) {
        self.locationService.geofenceCenter.asObservable()
            .map { (coordinate) -> (String?, String?) in
                let title = coordinate == nil ? "Select Coordinate" : "Change Coordinate"
                var subtitle: String? = nil
                if let coordinate = coordinate {
                    let lat = String(format: "%.4f", coordinate.latitude)
                    let lon = String(format: "%.4f", coordinate.longitude)
                    subtitle = "Coordinate: lat \(lat) lon \(lon)"
                }
                return (title, subtitle)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak cell] (title, subtitle) in
                cell?.textLabel?.text = title
                cell?.detailTextLabel?.text = subtitle
            })
            .disposed(by: cell.disposableOnReuse)
    }
    
    private func setupCellRadius(_ cell: DisposableTableViewCell) {
        cell.textLabel?.text = "Radius"
        self.locationService.geofenceRadius.asObservable()
            .map {
                $0 > 0 ? "\($0) meters" : "not set"
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak cell] (text) in
                cell?.detailTextLabel?.text = text
            })
            .disposed(by: cell.disposableOnReuse)
    }
    
    private func setupCellSummary(_ cell: DisposableTableViewCell) {
        let observable = Observable.combineLatest(
            self.locationService.regionStateObservable,
            self.locationService.isMonitoringObservable
        )
        observable
            .map { (state, isMonitoring) -> String in
                var summary: String = "Region monitoring: "
                summary += isMonitoring ? "active" : "off"
                summary += "\nRegion status: \(state?.humanReadableDescription ?? "no information")"
                return summary
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak cell] (title) in
                cell?.textLabel?.text = title
            })
            .disposed(by: cell.disposableOnReuse)
    }

    private func setupCellNotifications(_ cell: DisposableTableViewCell) {
        cell.textLabel?.text = "Notification persmissions"
        self.notificationService.authorizationStatusObservable
            .map {
                "sound:\($0.soundSetting.hrd)\nalert:\($0.alertSetting.hrd)\nbadge:\($0.badgeSetting.hrd)"
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak cell] (title) in
                cell?.detailTextLabel?.text = title
            })
            .disposed(by: cell.disposableOnReuse)
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
        case .notifications:
            self.checkRequestNotificationPermissions()
        }
    }    

// MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Row.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.defaultCellId) as? DisposableTableViewCell
            ?? DisposableTableViewCell(style: .subtitle, reuseIdentifier: self.defaultCellId)
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
            case .notifications:
                self.setupCellNotifications(cell)
            }
        }
        return cell
    }

}
