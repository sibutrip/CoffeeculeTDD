//
//  ChildRecord.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/13/23.
//

import CloudKit

/// A Record type that has a parent that is also a Record type.
///
/// Read the Record documentation for implementation tips.
protocol ChildRecord: Record {
    /// The parent of a Record, which must also be a Record.
    associatedtype Parent = Record
    /// The parent of a Record, which must also be a Record.
    var parent: Parent? { get set }
            
    /// Initializes an instance of a Record type from a CKRecord, when the parent Record is available.
    init?(from record: CKRecord, with parent: Parent)
}

extension ChildRecord {
    init?(from record: CKRecord) {
        return nil
    }
}


/// A Record type that has a parent that is also a Record type.
///
/// Read the Record documentation for implementation tips.
protocol ChildWithTwoParents: ChildRecord {
    /// The parent of a Record, which must also be a Record.
    associatedtype SecondParent = Record
    /// The parent of a Record, which must also be a Record.
    var secondParent: SecondParent? { get set }
    
    /// Initializes an instance of a Record type from a CKRecord, when the parent Record is available.
    init?(from record: CKRecord, with secondParent: SecondParent)
    init?(from record: CKRecord, firstParent: Parent, secondParent: SecondParent)
}

/// A Record type that has a parent that is also a Record type.
///
/// Read the Record documentation for implementation tips.
protocol ChildWithThreeParents: ChildWithTwoParents {
    /// The parent of a Record, which must also be a Record.
    associatedtype ThirdParent = Record
    /// The parent of a Record, which must also be a Record.
    var thirdParent: ThirdParent? { get set }
    
    init?(from record: CKRecord, firstParent: Parent, secondParent: SecondParent, thirdParent: ThirdParent)
}
