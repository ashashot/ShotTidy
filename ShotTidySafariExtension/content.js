//
// content.js — ShotTidySafariExtension
//
// Spike: shows a floating button near the current text selection.
// Clicking it sends the selected text to background.js → native handler
// and displays the native reply in a toast, proving the full roundtrip.
//

(() => {
    let button = null;
    let toast = null;

    function removeButton() {
        if (button) {
            button.remove();
            button = null;
        }
    }

    function showToast(message) {
        if (toast) toast.remove();
        toast = document.createElement("div");
        toast.className = "shottidier-toast";
        toast.textContent = message;
        document.documentElement.appendChild(toast);
        setTimeout(() => {
            if (toast) {
                toast.remove();
                toast = null;
            }
        }, 4000);
    }

    function showButton(rect, text) {
        removeButton();
        button = document.createElement("button");
        button.type = "button";
        button.className = "shottidier-selection-button";
        button.textContent = "Save to ShotTidier";
        button.style.top = `${window.scrollY + rect.bottom + 8}px`;
        button.style.left = `${window.scrollX + Math.max(rect.left, 0)}px`;

        // Prevent the button click from collapsing the selection.
        button.addEventListener("mousedown", (event) => event.preventDefault());

        button.addEventListener("click", () => {
            button.textContent = "Sending…";
            button.disabled = true;
            browser.runtime.sendMessage({
                type: "shottidier.selection",
                text: text,
                url: location.href,
                title: document.title
            }).then((reply) => {
                if (reply && reply.ok) {
                    showToast(`Native reply: ${JSON.stringify(reply.native)}`);
                } else {
                    showToast(`Error: ${reply ? reply.error : "no reply"}`);
                }
            }).catch((error) => {
                showToast(`Error: ${error}`);
            }).finally(removeButton);
        });

        document.documentElement.appendChild(button);
    }

    document.addEventListener("mouseup", () => {
        // Let the browser finish updating the selection first.
        setTimeout(() => {
            const selection = window.getSelection();
            const text = selection ? selection.toString().trim() : "";
            if (!text || selection.rangeCount === 0) {
                removeButton();
                return;
            }
            const rect = selection.getRangeAt(0).getBoundingClientRect();
            if (rect.width === 0 && rect.height === 0) {
                removeButton();
                return;
            }
            showButton(rect, text);
        }, 10);
    });

    document.addEventListener("selectionchange", () => {
        const selection = window.getSelection();
        if (!selection || selection.isCollapsed) {
            removeButton();
        }
    });
})();
