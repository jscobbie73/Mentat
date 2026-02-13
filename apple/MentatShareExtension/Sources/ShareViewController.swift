import UIKit
import Social
import UniformTypeIdentifiers

/// Share extension that allows users to share content from any app into Mentat.
final class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Accept any content with text
        return true
    }

    override func didSelectPost() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            extensionContext?.completeRequest(returningItems: nil)
            return
        }

        Task {
            var title = contentText ?? "Shared Content"
            var content = ""
            var sourceURL: String?

            for item in extensionItems {
                guard let attachments = item.attachments else { continue }

                for attachment in attachments {
                    // Handle URLs
                    if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                        if let url = try? await attachment.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                            sourceURL = url.absoluteString
                            if title.isEmpty { title = url.lastPathComponent }
                        }
                    }

                    // Handle plain text
                    if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                        if let text = try? await attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                            content += text
                        }
                    }

                    // Handle rich text / HTML
                    if attachment.hasItemConformingToTypeIdentifier(UTType.html.identifier) {
                        if let html = try? await attachment.loadItem(forTypeIdentifier: UTType.html.identifier) as? String {
                            // Strip HTML for plain content storage
                            content += html.strippingHTML()
                        }
                    }
                }
            }

            if content.isEmpty {
                content = title
            }

            // Send to Mentat backend
            do {
                let request = CreateFragmentRequest(
                    title: title,
                    content: content,
                    sourceUrl: sourceURL,
                    sourceType: "share",
                    metadata: nil
                )
                _ = try await APIClient.shared.createFragment(request)
            } catch {
                // Log error but still complete — content is saved locally
                print("Share extension: failed to sync fragment: \(error)")
            }

            extensionContext?.completeRequest(returningItems: nil)
        }
    }

    override func configurationItems() -> [Any]! {
        return []
    }
}

// MARK: - HTML stripping helper

extension String {
    func strippingHTML() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]
        guard let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return self
        }
        return attributed.string
    }
}
