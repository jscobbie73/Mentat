import Foundation
import HealthKit
import Observation

@Observable
final class HealthKitManager {
    var isConnected = false
    var statusDescription = "Not connected"

    private let store = HKHealthStore()

    // Phase 1: foundation only — request permissions, display status.
    // Phase 2 will write actual HKObjectType.categoryType dose events once the correct
    // public API type is confirmed (see SPEC.md §11 Q4 re: iOS 16 Medications section).
    private var typesToShare: Set<HKSampleType> {
        var types = Set<HKSampleType>()
        // Placeholder: mindfulSession is a valid writable category type used until
        // the medication-specific type is confirmed for App Store use.
        if let t = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(t)
        }
        return types
    }

    func requestPermission() async {
        guard HealthKitAvailability.isAvailable else {
            statusDescription = "HealthKit not available on this device"
            return
        }
        do {
            try await store.requestAuthorization(toShare: typesToShare, read: [])
            await checkStatus()
        } catch {
            statusDescription = "Permission request failed"
        }
    }

    func checkStatus() async {
        guard HealthKitAvailability.isAvailable else { return }
        guard let sampleType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return }
        let status = store.authorizationStatus(for: sampleType)
        switch status {
        case .sharingAuthorized:
            isConnected = true
            statusDescription = "Connected to Apple Health"
        case .sharingDenied:
            isConnected = false
            statusDescription = "Access denied — check Health app permissions"
        default:
            isConnected = false
            statusDescription = "Not connected"
        }
    }
}
