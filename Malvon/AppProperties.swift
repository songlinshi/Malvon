//
//  AppProperties.swift
//  Malvon
//
//  Created by Ashwin Paudel on 2021-12-31.
//  Copyright © 2021-2022 Ashwin Paudel. All rights reserved.
//

import Foundation

public struct AppProperties {
    var hidesScreenElementsWhenNotActive: Bool
    var isEnergySaverModeOn: Bool

    private let defaults = UserDefaults.standard

    public init() {
        hidesScreenElementsWhenNotActive = defaults.bool(forKey: "MA_APP_PROPERTIES_hidesScreenElementsWhenNotActive")
        isEnergySaverModeOn = defaults.bool(forKey: "MA_APP_PROPERTIES_isEnergySaverModeOn")
    }

    func set() {
        defaults.set(hidesScreenElementsWhenNotActive, forKey: "MA_APP_PROPERTIES_hidesScreenElementsWhenNotActive")
        defaults.set(isEnergySaverModeOn, forKey: "MA_APP_PROPERTIES_isEnergySaverModeOn")
    }
}
