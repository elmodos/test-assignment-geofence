//
//  DisposableTableViewCell.swift
//  geofence
//
//  Created by Modo Ltunzher on 1/4/19.
//  Copyright © 2019 Modo Ltunzher. All rights reserved.
//

import UIKit
import RxSwift

class DisposableTableViewCell: UITableViewCell {
    
    private(set) var disposableOnReuse = DisposeBag()
    override func prepareForReuse() {
        self.disposableOnReuse = DisposeBag()
        super.prepareForReuse()
    }

}
