//
// background.js — ShotTidySafariExtension
//
// Routes messages from the content script to the native app extension
// handler (SafariWebExtensionHandler) via native messaging.
//

browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (!message || message.type !== "shottidier.selection") {
        return false;
    }

    browser.runtime.sendNativeMessage("application.id", {
        action: "ping",
        text: message.text ?? "",
        url: message.url ?? "",
        title: message.title ?? ""
    }).then((response) => {
        sendResponse({ ok: true, native: response });
    }).catch((error) => {
        sendResponse({ ok: false, error: String(error) });
    });

    // Keep the message channel open for the async response.
    return true;
});
