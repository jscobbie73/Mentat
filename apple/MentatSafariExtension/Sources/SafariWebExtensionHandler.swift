import SafariServices
import os.log

/// Handles messages from the Safari Web Extension JavaScript context.
final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    private let logger = Logger(subsystem: "com.mentat.safari-extension", category: "handler")

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem

        let profile: UUID?
        if #available(iOS 17.0, macOS 14.0, *) {
            profile = request?.userInfo?[SFExtensionProfileKey] as? UUID
        } else {
            profile = nil
        }

        let message = request?.userInfo?[SFExtensionMessageKey]
        logger.info("Received message from browser: \(String(describing: message), privacy: .public) (profile: \(String(describing: profile), privacy: .public))")

        guard let messageDict = message as? [String: Any],
              let action = messageDict["action"] as? String else {
            let response = NSExtensionItem()
            response.userInfo = [SFExtensionMessageKey: ["error": "Invalid message format"]]
            context.completeRequest(returningItems: [response])
            return
        }

        Task {
            let responseData: [String: Any]

            switch action {
            case "capture":
                responseData = await handleCapture(messageDict)
            case "highlight":
                responseData = await handleHighlight(messageDict)
            case "getStatus":
                responseData = ["status": "connected", "version": "0.1.0"]
            default:
                responseData = ["error": "Unknown action: \(action)"]
            }

            let response = NSExtensionItem()
            response.userInfo = [SFExtensionMessageKey: responseData]
            context.completeRequest(returningItems: [response])
        }
    }

    private func handleCapture(_ message: [String: Any]) async -> [String: Any] {
        guard let title = message["title"] as? String,
              let content = message["content"] as? String,
              let url = message["url"] as? String else {
            return ["error": "Missing title, content, or url"]
        }

        do {
            let request = CreateFragmentRequest(
                title: title,
                content: content,
                sourceUrl: url,
                sourceType: "bookmark",
                metadata: nil
            )
            let fragment = try await APIClient.shared.createFragment(request)
            return ["success": true, "fragmentId": fragment.id.uuidString]
        } catch {
            logger.error("Failed to capture: \(error.localizedDescription)")
            return ["error": error.localizedDescription]
        }
    }

    private func handleHighlight(_ message: [String: Any]) async -> [String: Any] {
        guard let selectedText = message["selectedText"] as? String,
              let url = message["url"] as? String,
              let pageTitle = message["pageTitle"] as? String else {
            return ["error": "Missing selectedText, url, or pageTitle"]
        }

        do {
            let request = CreateFragmentRequest(
                title: "Highlight from: \(pageTitle)",
                content: selectedText,
                sourceUrl: url,
                sourceType: "highlight",
                metadata: nil
            )
            let fragment = try await APIClient.shared.createFragment(request)
            return ["success": true, "fragmentId": fragment.id.uuidString]
        } catch {
            logger.error("Failed to save highlight: \(error.localizedDescription)")
            return ["error": error.localizedDescription]
        }
    }
}
