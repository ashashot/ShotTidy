//
// content.js — ShotTidySafariExtension
//
// Shows a floating button near the current text selection. Clicking it opens
// a panel (shadow DOM) that analyzes the selection via the native handler
// (analyze-text Edge Function) and lets the user review, edit and save the
// extracted items into the ShotTidier catalog.
//

(() => {
    const BUILTIN_CATEGORIES = [
        ["shopping", "Shopping"],
        ["places", "Places"],
        ["appsServices", "Apps & Services"],
        ["languageLearning", "Language Learning"],
        ["prompts", "Prompts"],
        ["health", "Health"],
        ["recipes", "Recipes"],
        ["books", "Books"],
        ["movies", "Movies & TV Shows"],
        ["quotes", "Quotes"],
        ["articles", "Articles"],
        ["contacts", "Contacts"],
        ["tasks", "Tasks"],
    ];

    const PANEL_CSS = `
        :host { all: initial; }
        * { box-sizing: border-box; font-family: -apple-system, system-ui, sans-serif; }
        .overlay {
            position: fixed; inset: 0; z-index: 2147483647;
            background: rgba(0, 0, 0, 0.25);
            display: flex; align-items: flex-start; justify-content: flex-end;
            padding: 18px;
        }
        .panel {
            width: 380px; max-height: calc(100vh - 36px);
            display: flex; flex-direction: column;
            background: #f6f6f8; color: #1d1d1f;
            border-radius: 14px;
            box-shadow: 0 12px 40px rgba(0, 0, 0, 0.35);
            overflow: hidden;
        }
        @media (prefers-color-scheme: dark) {
            .panel { background: #232326; color: #f2f2f4; }
            .item { background: #2e2e32 !important; }
            .item input, .item select { background: #3a3a3f !important; color: #f2f2f4 !important; border-color: #4a4a4f !important; }
            .footer { border-color: #3a3a3f !important; }
        }
        .header {
            display: flex; align-items: center; justify-content: space-between;
            padding: 12px 16px; font-size: 14px; font-weight: 700;
        }
        .close {
            border: none; background: none; cursor: pointer;
            font-size: 15px; color: inherit; opacity: 0.55; padding: 4px;
        }
        .close:hover { opacity: 1; }
        .body { overflow-y: auto; padding: 0 12px 12px; }
        .status { padding: 28px 16px; text-align: center; font-size: 13px; line-height: 1.5; }
        .spinner {
            width: 22px; height: 22px; margin: 0 auto 12px;
            border: 3px solid rgba(120, 120, 128, 0.25);
            border-top-color: #4f7df9; border-radius: 50%;
            animation: st-spin 0.8s linear infinite;
        }
        @keyframes st-spin { to { transform: rotate(360deg); } }
        .item {
            background: #ffffff; border-radius: 10px;
            padding: 10px; margin-bottom: 8px;
            display: flex; gap: 8px; align-items: flex-start;
        }
        .item.deselected { opacity: 0.45; }
        .item input[type="checkbox"] { margin-top: 6px; }
        .fields { flex: 1; display: flex; flex-direction: column; gap: 6px; }
        .item select, .item input[type="text"] {
            width: 100%; padding: 5px 8px; font-size: 12px;
            border: 1px solid #d8d8dc; border-radius: 6px; background: #fbfbfd;
        }
        .item input.title { font-weight: 600; font-size: 13px; }
        .footer {
            display: flex; align-items: center; gap: 10px;
            padding: 12px 16px; border-top: 1px solid #e3e3e7;
        }
        .count { flex: 1; font-size: 12px; opacity: 0.6; }
        .save {
            border: none; border-radius: 8px; cursor: pointer;
            padding: 8px 18px; font-size: 13px; font-weight: 600;
            background: #4f7df9; color: #ffffff;
        }
        .save:disabled { opacity: 0.5; cursor: default; }
        .save:hover:not(:disabled) { background: #3d68e0; }
    `;

    let button = null;
    let panelHost = null;

    // MARK: - Native messaging helper

    function callNative(payload) {
        return browser.runtime.sendMessage({ type: "shottidier.native", payload });
    }

    // MARK: - Floating button

    function removeButton() {
        if (button) {
            button.remove();
            button = null;
        }
    }

    function showButton(rect, text) {
        removeButton();
        button = document.createElement("button");
        button.type = "button";
        button.className = "shottidier-selection-button";
        button.textContent = "Save to ShotTidier";
        button.style.top = `${window.scrollY + rect.bottom + 8}px`;
        button.style.left = `${window.scrollX + Math.max(rect.left, 0)}px`;
        button.addEventListener("mousedown", (event) => event.preventDefault());
        button.addEventListener("click", () => {
            removeButton();
            openPanel(text);
        });
        document.documentElement.appendChild(button);
    }

    document.addEventListener("mouseup", () => {
        setTimeout(() => {
            if (panelHost) return; // don't fight with the open panel
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

    // MARK: - Panel

    function closePanel() {
        if (panelHost) {
            panelHost.remove();
            panelHost = null;
        }
    }

    function openPanel(text) {
        closePanel();
        panelHost = document.createElement("div");
        const shadow = panelHost.attachShadow({ mode: "closed" });

        const style = document.createElement("style");
        style.textContent = PANEL_CSS;
        shadow.appendChild(style);

        const overlay = document.createElement("div");
        overlay.className = "overlay";
        overlay.addEventListener("click", (event) => {
            if (event.target === overlay) closePanel();
        });

        const panel = document.createElement("div");
        panel.className = "panel";

        const header = document.createElement("div");
        header.className = "header";
        header.textContent = "Save to ShotTidier";
        const close = document.createElement("button");
        close.className = "close";
        close.textContent = "✕";
        close.addEventListener("click", closePanel);
        header.appendChild(close);

        const body = document.createElement("div");
        body.className = "body";

        panel.appendChild(header);
        panel.appendChild(body);
        overlay.appendChild(panel);
        shadow.appendChild(overlay);
        document.documentElement.appendChild(panelHost);

        showStatus(body, "Analyzing selection…", true);

        callNative({ action: "getStatus" }).then((status) => {
            if (!status || !status.ok) {
                showStatus(body, `Error: ${status ? status.error : "no reply from app"}`);
                return;
            }
            if (!status.isPro) {
                showStatus(body,
                    "ShotTidier Pro is required to save from Safari.\n" +
                    "Open the ShotTidier app to subscribe or restore your purchase.");
                return;
            }
            analyze(body, panel, text, status.customCategories || []);
        }).catch((error) => {
            showStatus(body, `Error: ${error}`);
        });
    }

    function showStatus(body, message, spinning = false) {
        body.textContent = "";
        const status = document.createElement("div");
        status.className = "status";
        if (spinning) {
            const spinner = document.createElement("div");
            spinner.className = "spinner";
            status.appendChild(spinner);
        }
        message.split("\n").forEach((line) => {
            const p = document.createElement("div");
            p.textContent = line;
            status.appendChild(p);
        });
        body.appendChild(status);
    }

    function analyze(body, panel, text, customCategories) {
        callNative({
            action: "analyzeText",
            text: text,
            url: location.href,
            title: document.title
        }).then((reply) => {
            if (!reply || !reply.ok) {
                showStatus(body, `${reply ? reply.error : "No reply from the app."}`);
                return;
            }
            if (!reply.items || reply.items.length === 0) {
                showStatus(body, "No structured data found in the selection.");
                return;
            }
            renderItems(body, panel, reply.items, customCategories);
        }).catch((error) => {
            showStatus(body, `Error: ${error}`);
        });
    }

    function renderItems(body, panel, items, customCategories) {
        body.textContent = "";
        const state = items.map((item) => ({ ...item, selected: true }));

        const categoryOptions = BUILTIN_CATEGORIES.concat(
            customCategories.map((c) => [c.key, c.name])
        );

        state.forEach((item) => {
            const row = document.createElement("div");
            row.className = "item";

            const checkbox = document.createElement("input");
            checkbox.type = "checkbox";
            checkbox.checked = true;
            checkbox.addEventListener("change", () => {
                item.selected = checkbox.checked;
                row.classList.toggle("deselected", !checkbox.checked);
                updateFooter();
            });

            const fields = document.createElement("div");
            fields.className = "fields";

            const select = document.createElement("select");
            categoryOptions.forEach(([key, name]) => {
                const option = document.createElement("option");
                option.value = key;
                option.textContent = name;
                if (key === item.category) option.selected = true;
                select.appendChild(option);
            });
            // Unknown category key (shouldn't happen) — fall back to first option.
            if (!categoryOptions.some(([key]) => key === item.category)) {
                select.selectedIndex = 0;
                item.category = categoryOptions[0][0];
            }
            select.addEventListener("change", () => { item.category = select.value; });

            const titleInput = textInput(item.title, "Title", "title");
            titleInput.addEventListener("input", () => { item.title = titleInput.value; });

            const subtitleInput = textInput(item.subtitle, "Details");
            subtitleInput.addEventListener("input", () => { item.subtitle = subtitleInput.value; });

            const linkInput = textInput(item.link, "Link");
            linkInput.addEventListener("input", () => { item.link = linkInput.value; });

            fields.appendChild(select);
            fields.appendChild(titleInput);
            fields.appendChild(subtitleInput);
            fields.appendChild(linkInput);

            row.appendChild(checkbox);
            row.appendChild(fields);
            body.appendChild(row);
        });

        const footer = document.createElement("div");
        footer.className = "footer";
        const count = document.createElement("div");
        count.className = "count";
        const save = document.createElement("button");
        save.className = "save";
        save.textContent = "Save";
        footer.appendChild(count);
        footer.appendChild(save);
        panel.appendChild(footer);

        function selectedItems() {
            return state.filter((item) => item.selected && item.title.trim().length > 0);
        }

        function updateFooter() {
            const n = selectedItems().length;
            count.textContent = `${n} item${n === 1 ? "" : "s"} selected`;
            save.disabled = n === 0;
        }
        updateFooter();

        save.addEventListener("click", () => {
            save.disabled = true;
            save.textContent = "Saving…";
            const payload = selectedItems().map((item) => ({
                category: item.category,
                title: item.title,
                subtitle: item.subtitle || "",
                link: item.link || "",
                extra1: item.extra1 || "",
                extra2: item.extra2 || "",
                notes: item.notes || ""
            }));
            callNative({ action: "saveItems", items: payload }).then((reply) => {
                footer.remove();
                if (reply && reply.ok) {
                    showStatus(body, `Saved ${reply.saved} item${reply.saved === 1 ? "" : "s"}.\nThey will appear in ShotTidier and sync via iCloud.`);
                    setTimeout(closePanel, 2500);
                } else {
                    showStatus(body, `Error: ${reply ? reply.error : "save failed"}`);
                }
            }).catch((error) => {
                footer.remove();
                showStatus(body, `Error: ${error}`);
            });
        });
    }

    function textInput(value, placeholder, extraClass) {
        const input = document.createElement("input");
        input.type = "text";
        input.value = value || "";
        input.placeholder = placeholder;
        if (extraClass) input.classList.add(extraClass);
        return input;
    }
})();
