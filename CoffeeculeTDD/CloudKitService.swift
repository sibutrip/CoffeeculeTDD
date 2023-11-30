//
//  CloudKitService.swift
//  CoffeeculeTDD
//
//  Created by Cory Tripathy on 11/11/23.
//

import CloudKit

actor CloudKitService<Container: DataContainer>: CKServiceProtocol {
    private let container: Container
    var user: User?
    
    lazy var database: Database = container.public
    
    enum CloudKitError: Error {
        case invalidRequest, unexpectedResultFromServer, recordAlreadyExists, recordDoesNotExist, couldNotCreateModelFromCkRecord, childRecordsNotFound, userNotFound, missingParentRecord
    }
    
    func updatedRecord<SomeRecord: Record>(for record: SomeRecord) async throws -> SomeRecord {
        do {
            let ckRecord = try await database.record(for: record.recordID)
            guard let record = SomeRecord(from: ckRecord) else {
                throw CloudKitError.couldNotCreateModelFromCkRecord
            }
            return record
        } catch {
            throw CloudKitError.recordDoesNotExist
        }
    }
    
    func authenticate() async throws {
        let accountStatus = try await container.accountStatus()
        switch accountStatus {
        case .available:
            do {
                let userID = try await container.userRecordID()
                guard let user: User = try? await records(matchingValue: userID.recordName, inField: .systemUserID).first else {
                    self.user = User(systemUserID: userID.recordName)
                    return
                }
                self.user = user
            } catch {
                throw AuthenticationError.iCloudDriveDisabled
            }
        case .couldNotDetermine:
            throw AuthenticationError.couldNotDetermineAccountStatus
        case .restricted:
            throw AuthenticationError.accountRestricted
        case .noAccount:
            throw AuthenticationError.noAccount
        case .temporarilyUnavailable:
            throw AuthenticationError.accountTemporarilyUnavailable
        @unknown default:
            throw AuthenticationError.couldNotDetermineAccountStatus
        }
    }
    
    func save<SomeRecord: Record>(record: SomeRecord) async throws -> SomeRecord{
        do {
            let ckRecord = record.ckRecord
            let returnedCkRecord = try await database.save(ckRecord)
            guard let record = SomeRecord(from: returnedCkRecord) else {
                throw CloudKitError.couldNotCreateModelFromCkRecord
            }
            return record
        } catch {
            throw CloudKitError.invalidRequest
        }
    }
    
    func fetch<SomeRecord: Record>() async throws -> [SomeRecord] {
        let (results,_) = try await database.records(
            matching: CKQuery(recordType: SomeRecord.recordType, predicate: NSPredicate(value: true)),
            inZoneWith: nil,
            desiredKeys: nil,
            resultsLimit: CKQueryOperation.maximumResults)
        let ckRecords = results.compactMap { result in
            try? result.1.get()
        }
        let someRecords: [SomeRecord] = ckRecords.compactMap { SomeRecord(from: $0) }
        return someRecords
    }
    
    func remove<SomeRecord: Record>(_ record: SomeRecord) async throws {
        let (_, deleteResults) = try await database.modifyRecords(saving: [], deleting: [record.recordID])
        guard let deleteResult = deleteResults.first else {
            throw CloudKitError.invalidRequest
        }
        if deleteResult.key != record.recordID {
            throw CloudKitError.recordDoesNotExist
        }
    }
    
//    func children<Child: ChildRecord, Parent: Record>(of parent: Parent) async throws -> [Child] where Child.Parent == Parent {
//        let reference = CKRecord.Reference(recordID: parent.recordID, action: .none)
//        let predicate = NSPredicate(format: "\(Parent.recordType) == %@", reference)
//        let query = CKQuery(recordType: Child.recordType, predicate: predicate)
//        
//        let records = try await database.records(matching: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults)
//        let unwrappedRecords = records.matchResults.compactMap { record in
//            try? record.1.get()
//        }
//        
//        return unwrappedRecords.compactMap { record in
//            Child(from: record, with: parent)
//        }
//    }
    
    func children<Parent: Record, Child: ChildRecord>(of parent: Parent, returning child: Child.Type) async throws -> [CKRecord] where Child.Parent == Parent {
        let reference = CKRecord.Reference(recordID: parent.recordID, action: .none)
        let predicate = NSPredicate(format: "\(Parent.recordType) == %@", reference)
        let query = CKQuery(recordType: Child.recordType, predicate: predicate)
        
        let records = try await database.records(matching: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults)
        let unwrappedRecords = records.matchResults.compactMap { record in
            try? record.1.get()
        }
        
        return unwrappedRecords
    }
    
    #warning("change test to make this return value")
    func update<SomeRecord: Record>(record: SomeRecord, updatingFields fields: [SomeRecord.RecordKeys]) async throws -> SomeRecord {
        let fetchedCkRecord = try! await database.record(for: record.recordID)
        for field in fields {
            guard let fieldKey = field.rawValue as? CKRecord.FieldKey else { throw CloudKitError.invalidRequest }
            let newField = record.ckRecord[fieldKey]
            fetchedCkRecord[fieldKey] = newField
        }
        do {
            let (saveResult,_) = try await database.modifyRecords(saving: [fetchedCkRecord], deleting: [])
            guard let returnedResult = saveResult[record.recordID] else {
                throw CloudKitError.invalidRequest
            }
            let returnedCkRecord = try returnedResult.get()
                    guard let returnedRecord = SomeRecord(from: returnedCkRecord) else {
                throw CloudKitError.invalidRequest
            }
            return returnedRecord
        } catch {
            throw CloudKitError.invalidRequest
        }
    }
    
    func saveWithOneParent<Child: ChildRecord, Parent: Record>(_ record: Child) async throws where Child.RecordKeys.AllCases == [Child.RecordKeys], Child.Parent == Parent {
        guard let parent = record.parent else {
            throw CloudKitError.missingParentRecord
        }
        let childCkRecord = record.ckRecord
        childCkRecord.setValue(parent.reference, forKey: Parent.recordType)
        do {
            let _ = try await database.save(childCkRecord)
        } catch {
            throw CloudKitError.recordAlreadyExists
        }
    }
    
    func saveWithTwoParents<Child: ChildWithTwoParents, FirstParent: Record, SecondParent: Record>(_ record: Child) async throws where Child.Parent == FirstParent, Child.SecondParent == SecondParent {
        guard let firstParent = record.parent,
              let secondParent = record.secondParent else {
            throw CloudKitError.missingParentRecord
        }
        let childCkRecord = record.ckRecord
        childCkRecord.setValue(firstParent.reference, forKey: FirstParent.recordType)
        childCkRecord.setValue(secondParent.reference, forKey: SecondParent.recordType)
        do {
            let _ = try await database.save(childCkRecord)
        } catch {
            throw CloudKitError.recordAlreadyExists
        }
    }
    
    func saveWithThreeParents<Child: ChildWithThreeParents, FirstParent: Record, SecondParent: Record, ThirdParent: Record>(_ record: Child) async throws where Child.Parent == FirstParent, Child.SecondParent == SecondParent, Child.ThirdParent == ThirdParent {
        guard let firstParent = record.parent,
              let secondParent = record.secondParent,
              let thirdParent = record.thirdParent else {
            throw CloudKitError.missingParentRecord
        }
        let childCkRecord = record.ckRecord
        childCkRecord.setValue(firstParent.reference, forKey: FirstParent.recordType)
        childCkRecord.setValue(secondParent.reference, forKey: "Buyer")
        childCkRecord.setValue(thirdParent.reference, forKey: "Receiver")
        do {
            let _ = try await database.save(childCkRecord)
        } catch {
            throw CloudKitError.recordAlreadyExists
        }
    }
    
    func twoParentChildren<Child: ChildWithTwoParents, FirstParent: Record, SecondParent: Record>(of parent: FirstParent? = nil, secondParent: SecondParent? = nil) async throws -> [Child] where Child : ChildRecord, FirstParent : Record, FirstParent == Child.Parent, SecondParent == Child.SecondParent {
        if parent?.ckRecord == secondParent?.ckRecord && parent?.ckRecord == nil {
            throw CloudKitError.missingParentRecord
        }
        
        var predicate: NSPredicate?
        if let parent {
            let reference = CKRecord.Reference(recordID: parent.recordID, action: .none)
            predicate = NSPredicate(format: "\(FirstParent.recordType) == %@", reference)
        }
        if let secondParent {
            let reference = CKRecord.Reference(recordID: secondParent.recordID, action: .none)
            predicate = NSPredicate(format: "\(SecondParent.recordType) == %@", reference)
        }
        guard let predicate else { throw CloudKitError.missingParentRecord }
        
        let query = CKQuery(recordType: Child.recordType, predicate: predicate)
        
        let records = try await database.records(matching: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults)
        let unwrappedRecords = records.matchResults.compactMap { record in
            try? record.1.get()
        }
        
        let childRecords = try await withThrowingTaskGroup(of: Child?.self, returning: [Child].self) { group in
            for record in unwrappedRecords {
                group.addTask {
                    var fetchedParentCkRecord: CKRecord?
                    var fetchedSecondParentCkRecord: CKRecord?
                    if parent == nil {
                        if let parentReference = record[FirstParent.recordType] as? CKRecord.Reference {
                            fetchedParentCkRecord = try await self.database.record(for: parentReference.recordID)
                        }
                    } else {
                        if let secondParentReference = record[SecondParent.recordType] as? CKRecord.Reference {
                            fetchedSecondParentCkRecord = try await self.database.record(for: secondParentReference.recordID)
                        }
                    }
                    guard let parentCkRecord = fetchedParentCkRecord ?? (parent?.ckRecord ?? secondParent?.ckRecord),
                          let secondParentCkRecord = fetchedSecondParentCkRecord ?? (secondParent?.ckRecord ?? parent?.ckRecord) else {
                        throw CloudKitError.missingParentRecord
                    }
                    guard let parentRecord = FirstParent(from: parentCkRecord),
                          let secondParentRecord = SecondParent(from: secondParentCkRecord) else {
                        throw CloudKitError.couldNotCreateModelFromCkRecord
                    }
                    return Child(from: record, firstParent: parentRecord, secondParent: secondParentRecord)
                }
            }
            
            var childRecords = [Child]()
            while let child = try await group.next() {
                if let child {
                    childRecords.append(child)
                }
            }
            return childRecords
        }
        return childRecords
    }
    
    #warning("broken now :(")
    func threeParentChildren<Child: ChildWithThreeParents, FirstParent: Record, SecondParent: Record, ThirdParent: Record>(of parent: FirstParent? = nil, secondParent: SecondParent? = nil, thirdParent: ThirdParent? = nil) async throws -> [Child] where Child : ChildRecord, FirstParent : Record, FirstParent == Child.Parent, SecondParent == Child.SecondParent, ThirdParent == Child.ThirdParent {
        
        if parent?.ckRecord == secondParent?.ckRecord && parent?.ckRecord == thirdParent?.ckRecord && parent?.ckRecord == nil {
            throw CloudKitError.missingParentRecord
        }
        
        var predicate: NSPredicate?
        if let parent {
            let reference = CKRecord.Reference(recordID: parent.recordID, action: .none)
            predicate = NSPredicate(format: "\(FirstParent.recordType) == %@", reference)
        }
        if let secondParent {
            let reference = CKRecord.Reference(recordID: secondParent.recordID, action: .none)
            predicate = NSPredicate(format: "Buyer == %@", reference)
        }
        if let thirdParent {
            let reference = CKRecord.Reference(recordID: thirdParent.recordID, action: .none)
            predicate = NSPredicate(format: "Receiver == %@", reference)
        }
        guard let predicate else { throw CloudKitError.missingParentRecord }
        
        let query = CKQuery(recordType: Child.recordType, predicate: predicate)
        
        let records = try await database.records(matching: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults)
        let unwrappedRecords = records.matchResults.compactMap { record in
            try? record.1.get()
        }
        
        if unwrappedRecords.isEmpty {
            throw CloudKitError.childRecordsNotFound
        }
        
        let recordToFetchParents = unwrappedRecords[0]
        
        async let firstParentCkRecordTask: CKRecord? = {
            if parent == nil {
                if let reference = recordToFetchParents[FirstParent.recordType] as? CKRecord.Reference {
                    return try await self.database.record(for: reference.recordID)
                }
            }
            return nil
        }()
        async let secondParentCkRecordTask: CKRecord? = {
            if secondParent == nil {
                if let reference = recordToFetchParents["Buyer"] as? CKRecord.Reference {
                    return try await self.database.record(for: reference.recordID)
                }
            }
            return nil
        }()
        async let thirdParentCkRecordTask: CKRecord? = {
            if thirdParent == nil {
                if let reference = recordToFetchParents["Receiver"] as? CKRecord.Reference {
                    return try await self.database.record(for: reference.recordID)
                }
            }
            return nil
        }()
        let (fetchedParentCkRecord, fetchedSecondParentCkRecord, fetchedThirdParentCkRecord) = try await (firstParentCkRecordTask, secondParentCkRecordTask, thirdParentCkRecordTask)
        
        let childRecords = try await withThrowingTaskGroup(of: Child?.self, returning: [Child].self) { group in
            for record in unwrappedRecords {
                group.addTask {
                    
                    guard let parentCkRecord = fetchedParentCkRecord ?? (parent?.ckRecord ?? secondParent?.ckRecord),
                          let secondParentCkRecord = fetchedSecondParentCkRecord ?? (secondParent?.ckRecord ?? parent?.ckRecord),
                          let thirdParentCkRecord = fetchedThirdParentCkRecord ?? (thirdParent?.ckRecord ?? secondParent?.ckRecord)
                    else {
                        throw CloudKitError.missingParentRecord
                    }
                    guard let parentRecord = FirstParent(from: parentCkRecord),
                          let secondParentRecord = SecondParent(from: secondParentCkRecord),
                          let thirdParentRecord = ThirdParent(from: thirdParentCkRecord) else {
                        throw CloudKitError.couldNotCreateModelFromCkRecord
                    }
                    return Child(from: record, firstParent: parentRecord, secondParent: secondParentRecord, thirdParent: thirdParentRecord)
                }
            }
                
            var childRecords = [Child]()
            while let child = try await group.next() {
                if let child {
                    childRecords.append(child)
                }
            }
            return childRecords
        }
        return childRecords
    }
    
    #warning("add test to this")
    func records<SomeRecord: Record>(matchingValue value: CVarArg, inField field: SomeRecord.RecordKeys) async throws -> [SomeRecord] {
        let predicate = NSPredicate(format: "\(field) == %@", value)
        let query = CKQuery(recordType: SomeRecord.recordType, predicate: predicate)
        let fetchedRecords = try await database.records(matching: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults)
        let unwrappedRecords = fetchedRecords.matchResults.compactMap { record in
            try? record.1.get()
        }
        if unwrappedRecords.isEmpty {
            throw CloudKitError.recordDoesNotExist
        }
        
        return unwrappedRecords.compactMap { record in
            SomeRecord(from: record)
        }
    }
    
    init(with container: Container) async throws {
        self.container = container
        try await authenticate()
    }
}

extension CloudKitService {
    enum AuthenticationError: LocalizedError, CaseIterable {
        case noAccount, accountRestricted, couldNotDetermineAccountStatus, accountTemporarilyUnavailable, iCloudDriveDisabled
        
        public var errorDescription: String? {
            switch self {
            case .noAccount:
                return NSLocalizedString("Please create or log into an iCloud account in system settings before continuing.", comment: "Error when user does not have an iCloud account.")
            case .accountRestricted:
                return NSLocalizedString("iCloud account is restricted.", comment: "Error when user has a restricted iCloud account.")
            case .couldNotDetermineAccountStatus:
                return NSLocalizedString("There was a problem getting your iCloud account details. Make sure you're connected to the internet and both iCloud and iCloud Drive are enabled in system settings.", comment: "Error when CloudKit cannot determine iCloud account status.")
            case .accountTemporarilyUnavailable:
                return NSLocalizedString("iCloud account temporarily unavailable. Please try again later.", comment: "Error when user's iCloud account is temporarily unavailable.")
            case .iCloudDriveDisabled:
                return NSLocalizedString("Please enable iCloud drive in system settings before continuing.", comment: "Error when iCloud Drive is not enabled for a user.")
            }
        }
    }
}

