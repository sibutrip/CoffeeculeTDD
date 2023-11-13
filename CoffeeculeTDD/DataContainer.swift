//
//  DataContainer.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/12/23.
//

import CloudKit

protocol DataContainer {
    static var `private`: DataStore { get }
    static var shared: DataStore { get }
    static var `public`: DataStore { get }
}
