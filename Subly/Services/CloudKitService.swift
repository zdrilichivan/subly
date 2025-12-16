//
//  CloudKitService.swift
//  SublySwift
//
//  Servizio per la sincronizzazione con CloudKit/iCloud
//

import Foundation
import CloudKit
import Combine
import OSLog

class CloudKitService: ObservableObject {

    // MARK: - Singleton
    static let shared = CloudKitService()

    // MARK: - Properties
    private let container: CKContainer
    private let database: CKDatabase
    private let logger = Logger(subsystem: "com.ivanzdrilich.SublySwift", category: "CloudKitService")

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?

    // MARK: - Init
    private init() {
        self.container = CKContainer(identifier: Constants.CloudKit.containerIdentifier)
        self.database = container.privateCloudDatabase
    }

    // MARK: - Account Status
    func checkAccountStatus() async -> Bool {
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                logger.info("✅ iCloud account available")
                return true
            case .noAccount:
                logger.warning("⚠️ No iCloud account")
                return false
            case .restricted:
                logger.warning("⚠️ iCloud account restricted")
                return false
            case .couldNotDetermine:
                logger.warning("⚠️ Could not determine iCloud status")
                return false
            case .temporarilyUnavailable:
                logger.warning("⚠️ iCloud temporarily unavailable")
                return false
            @unknown default:
                logger.warning("⚠️ Unknown iCloud status")
                return false
            }
        } catch {
            logger.error("❌ Error checking iCloud status: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Save Subscription
    func saveSubscription(_ subscription: Subscription) async throws {
        let record = subscriptionToRecord(subscription)

        do {
            _ = try await database.save(record)
            logger.info("✅ Saved subscription: \(subscription.displayName)")
        } catch let error as CKError {
            handleCloudKitError(error)
            throw error
        }
    }

    // MARK: - Update Subscription
    func updateSubscription(_ subscription: Subscription) async throws {
        // Fetch existing record first
        let recordID = CKRecord.ID(recordName: subscription.id.uuidString)

        do {
            let existingRecord = try await database.record(for: recordID)
            updateRecord(existingRecord, with: subscription)
            _ = try await database.save(existingRecord)
            logger.info("✅ Updated subscription: \(subscription.displayName)")
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist, create new one
            try await saveSubscription(subscription)
        } catch {
            logger.error("❌ Error updating subscription: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Delete Subscription
    func deleteSubscription(_ subscription: Subscription) async throws {
        let recordID = CKRecord.ID(recordName: subscription.id.uuidString)

        do {
            try await database.deleteRecord(withID: recordID)
            logger.info("✅ Deleted subscription: \(subscription.displayName)")
        } catch let error as CKError where error.code == .unknownItem {
            // Record already deleted, ignore
            logger.info("ℹ️ Subscription already deleted: \(subscription.displayName)")
        } catch {
            logger.error("❌ Error deleting subscription: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Fetch All Subscriptions
    func fetchAllSubscriptions() async throws -> [Subscription] {
        let query = CKQuery(
            recordType: Constants.CloudKit.subscriptionRecordType,
            predicate: NSPredicate(value: true)
        )
        query.sortDescriptors = [NSSortDescriptor(key: "nextBillingDate", ascending: true)]

        do {
            let (matchResults, _) = try await database.records(matching: query)
            var subscriptions: [Subscription] = []

            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let subscription = recordToSubscription(record) {
                        subscriptions.append(subscription)
                    }
                case .failure(let error):
                    logger.warning("⚠️ Error fetching record: \(error.localizedDescription)")
                }
            }

            logger.info("✅ Fetched \(subscriptions.count) subscriptions from CloudKit")
            await MainActor.run {
                self.lastSyncDate = Date()
            }
            return subscriptions

        } catch {
            logger.error("❌ Error fetching subscriptions: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Sync
    func sync(localSubscriptions: [Subscription]) async -> [Subscription] {
        await MainActor.run {
            self.isSyncing = true
            self.syncError = nil
        }

        defer {
            Task { @MainActor in
                self.isSyncing = false
            }
        }

        // Check account status
        guard await checkAccountStatus() else {
            logger.warning("⚠️ iCloud not available, using local data only")
            return localSubscriptions
        }

        do {
            let cloudSubscriptions = try await fetchAllSubscriptions()
            let merged = mergeSubscriptions(local: localSubscriptions, cloud: cloudSubscriptions)
            return merged
        } catch {
            await MainActor.run {
                self.syncError = error
            }
            logger.error("❌ Sync failed: \(error.localizedDescription)")
            return localSubscriptions
        }
    }

    // MARK: - Private: Record Conversion

    private func subscriptionToRecord(_ subscription: Subscription) -> CKRecord {
        let recordID = CKRecord.ID(recordName: subscription.id.uuidString)
        let record = CKRecord(recordType: Constants.CloudKit.subscriptionRecordType, recordID: recordID)

        record["serviceName"] = subscription.serviceName
        record["customName"] = subscription.customName
        record["cost"] = subscription.cost
        record["currency"] = subscription.currency
        record["billingCycle"] = subscription.billingCycle.rawValue
        record["nextBillingDate"] = subscription.nextBillingDate
        record["notes"] = subscription.notes
        record["isActive"] = subscription.isActive ? 1 : 0
        record["category"] = subscription.category.rawValue
        record["isEssential"] = subscription.isEssential ? 1 : 0
        record["createdAt"] = subscription.createdAt
        record["updatedAt"] = subscription.updatedAt

        return record
    }

    private func updateRecord(_ record: CKRecord, with subscription: Subscription) {
        record["serviceName"] = subscription.serviceName
        record["customName"] = subscription.customName
        record["cost"] = subscription.cost
        record["currency"] = subscription.currency
        record["billingCycle"] = subscription.billingCycle.rawValue
        record["nextBillingDate"] = subscription.nextBillingDate
        record["notes"] = subscription.notes
        record["isActive"] = subscription.isActive ? 1 : 0
        record["category"] = subscription.category.rawValue
        record["isEssential"] = subscription.isEssential ? 1 : 0
        record["updatedAt"] = subscription.updatedAt
    }

    private func recordToSubscription(_ record: CKRecord) -> Subscription? {
        guard
            let idString = record.recordID.recordName as String?,
            let id = UUID(uuidString: idString),
            let serviceName = record["serviceName"] as? String,
            let cost = record["cost"] as? Double,
            let billingCycleRaw = record["billingCycle"] as? String,
            let billingCycle = BillingCycle(rawValue: billingCycleRaw),
            let nextBillingDate = record["nextBillingDate"] as? Date,
            let categoryRaw = record["category"] as? String,
            let category = ServiceCategory(rawValue: categoryRaw)
        else {
            return nil
        }

        return Subscription(
            id: id,
            serviceName: serviceName,
            customName: record["customName"] as? String,
            cost: cost,
            currency: record["currency"] as? String ?? "EUR",
            billingCycle: billingCycle,
            nextBillingDate: nextBillingDate,
            notes: record["notes"] as? String,
            isActive: (record["isActive"] as? Int ?? 1) == 1,
            category: category,
            isEssential: (record["isEssential"] as? Int ?? 0) == 1,
            createdAt: record["createdAt"] as? Date ?? Date(),
            updatedAt: record["updatedAt"] as? Date ?? Date()
        )
    }

    // MARK: - Private: Merge Logic

    private func mergeSubscriptions(local: [Subscription], cloud: [Subscription]) -> [Subscription] {
        var merged: [Subscription] = []
        var localMap = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })

        // Process cloud subscriptions
        for cloudSub in cloud {
            if let localSub = localMap[cloudSub.id] {
                // Both exist: use the most recently updated one
                if localSub.updatedAt > cloudSub.updatedAt {
                    merged.append(localSub)
                    // Update cloud with local changes
                    Task {
                        try? await updateSubscription(localSub)
                    }
                } else {
                    merged.append(cloudSub)
                }
                localMap.removeValue(forKey: cloudSub.id)
            } else {
                // Only in cloud
                merged.append(cloudSub)
            }
        }

        // Add remaining local subscriptions (not in cloud)
        for (_, localSub) in localMap {
            merged.append(localSub)
            // Upload to cloud
            Task {
                try? await saveSubscription(localSub)
            }
        }

        // Sort by next billing date
        merged.sort { $0.nextBillingDate < $1.nextBillingDate }

        logger.info("✅ Merged subscriptions: \(merged.count) total")
        return merged
    }

    // MARK: - Private: Error Handling

    private func handleCloudKitError(_ error: CKError) {
        switch error.code {
        case .networkUnavailable:
            logger.warning("⚠️ Network unavailable")
        case .networkFailure:
            logger.warning("⚠️ Network failure")
        case .serviceUnavailable:
            logger.warning("⚠️ CloudKit service unavailable")
        case .quotaExceeded:
            logger.error("❌ iCloud quota exceeded")
        case .notAuthenticated:
            logger.warning("⚠️ Not authenticated to iCloud")
        default:
            logger.error("❌ CloudKit error: \(error.localizedDescription)")
        }
    }
}
