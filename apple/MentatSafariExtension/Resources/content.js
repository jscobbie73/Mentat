// Mentat Safari Extension - Content Script
// Injected into web pages to enable highlight capture.

(function () {
  "use strict";

  // Listen for messages from the background script
  browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (message.action === "getSelection") {
      const selection = window.getSelection();
      sendResponse({
        selectedText: selection ? selection.toString() : "",
        pageTitle: document.title,
        url: window.location.href,
      });
    }
  });
})();
