import HealthKit

enum HealthKitAvailability {
    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
}
