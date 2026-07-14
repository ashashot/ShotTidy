//
// background.js — ShotTidySafariExtension
//
// Generic proxy: forwards messages from the content script to the native
// app-extension handler (SafariWebExtensionHandler) and returns its reply.
//

browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (!message || message.type !== "shottidier.native" || !message.payload) {
        return false;
    }

    browser.runtime.sendNativeMessage("application.id", message.payload)
        .then((response) => {
            sendResponse(response ?? { ok: false, error: "Empty native reply" });
        })
        .catch((error) => {
            sendResponse({ ok: false, error: String(error) });
        });

    // Keep the message channel open for the async response.
    return true;
});
