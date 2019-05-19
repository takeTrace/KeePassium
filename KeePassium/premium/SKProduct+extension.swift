//
//  SKProduct+extension.swift
//  KeePassium
//
//  Created by Andrei Popleteev on 2019-05-18.
//  Copyright © 2019 Andrei Popleteev. All rights reserved.
//

import StoreKit
import UIKit

extension SKProduct {
    
    /// Price of the product in local currency.
    /// In case of locale trouble, falls back to number-only result.
    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.locale = priceLocale
        formatter.numberStyle = .currency
        return formatter.string(from: price) ?? String(format: "%.2f", price)
    }
}
