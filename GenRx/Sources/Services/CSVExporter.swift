import Foundation

enum CSVExporter {
    static func export(logs: [DoseLog]) -> String {
        var lines = ["Date,Time,Medication,Dosage,Status,Site,Notes"]
        let sorted = logs.sorted { $0.scheduledTime < $1.scheduledTime }
        for log in sorted {
            let date = log.scheduledTime.formatted(.dateTime.day().month().year())
            let time = log.scheduledTime.formatted(.dateTime.hour().minute())
            let med = escape(log.medicationName)
            let status = log.status.rawValue
            let site = escape(log.injectionSite ?? "")
            let notes = escape(log.notes)
            lines.append("\(date),\(time),\(med),\(status),\(site),\(notes)")
        }
        return lines.joined(separator: "\n")
    }

    static func shareURL(logs: [DoseLog]) throws -> URL {
        let csv = export(logs: logs)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("genrx-export-\(Int(Date().timeIntervalSince1970)).csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
