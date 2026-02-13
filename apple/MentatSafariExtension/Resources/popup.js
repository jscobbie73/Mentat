// Mentat Safari Extension - Popup Script

const statusEl = document.getElementById("status");

function showStatus(message, type = "") {
  statusEl.textContent = message;
  statusEl.className = `status ${type}`;
  if (type === "success") {
    setTimeout(() => { statusEl.textContent = ""; }, 3000);
  }
}

document.getElementById("save-page").addEventListener("click", async () => {
  try {
    const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
    const response = await browser.runtime.sendNativeMessage("application.id", {
      action: "capture",
      title: tab.title || "Untitled",
      content: tab.title || "",
      url: tab.url,
    });

    if (response.error) {
      showStatus(response.error, "error");
    } else {
      showStatus("Saved to Mentat!", "success");
    }
  } catch (err) {
    showStatus("Failed to save page", "error");
  }
});

document.getElementById("save-selection").addEventListener("click", async () => {
  try {
    const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
    const [{ result: selectedText }] = await browser.tabs.executeScript(tab.id, {
      code: "window.getSelection().toString()",
    });

    if (!selectedText) {
      showStatus("No text selected on the page", "error");
      return;
    }

    const response = await browser.runtime.sendNativeMessage("application.id", {
      action: "highlight",
      selectedText,
      url: tab.url,
      pageTitle: tab.title || "Untitled",
    });

    if (response.error) {
      showStatus(response.error, "error");
    } else {
      showStatus("Highlight saved!", "success");
    }
  } catch (err) {
    showStatus("Failed to save selection", "error");
  }
});
