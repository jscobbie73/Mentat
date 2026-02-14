// Mentat Safari Extension - Content Script
// Injected into web pages to enable highlight capture.

(function () {
  "use strict";

  // Listen for messages from the popup or background script
  browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (message.action === "getSelection" || message.type === "getSelection") {
      const selection = window.getSelection();
      const text = selection ? selection.toString() : "";
      // Return the selected text directly for the popup's sendMessage call
      sendResponse(text);
    }
  });
})();
