// Mentat Safari Extension - Background Service Worker

// Context menu: "Save to Mentat"
browser.contextMenus.create({
  id: "save-to-mentat",
  title: "Save to Mentat",
  contexts: ["page", "selection", "link"],
});

// Context menu: "Save Highlight to Mentat"
browser.contextMenus.create({
  id: "highlight-to-mentat",
  title: "Save Highlight to Mentat",
  contexts: ["selection"],
});

browser.contextMenus.onClicked.addListener(async (info, tab) => {
  if (info.menuItemId === "save-to-mentat") {
    const response = await browser.runtime.sendNativeMessage(
      "com.mentat.app.Extension",
      {
        action: "capture",
        title: tab.title || "Untitled",
        content: info.selectionText || tab.title || "",
        url: info.pageUrl || tab.url,
      }
    );
    handleResponse(response);
  }

  if (info.menuItemId === "highlight-to-mentat") {
    const response = await browser.runtime.sendNativeMessage(
      "com.mentat.app.Extension",
      {
        action: "highlight",
        selectedText: info.selectionText,
        url: info.pageUrl || tab.url,
        pageTitle: tab.title || "Untitled",
      }
    );
    handleResponse(response);
  }
});

function handleResponse(response) {
  if (response.error) {
    console.error("Mentat extension error:", response.error);
  }
}
