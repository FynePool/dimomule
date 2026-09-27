(() => {
  const MARKER = "DIMOMULE_1_0_ADDALL";
  const pendingAddAll = new Map();

  const isEd2k = value =>
    typeof value === "string" && /^ed2k:\/\//i.test(value.trim());

  const parseAddAll = value => {
    if (typeof value !== "string") return null;
    const m = value.trim().match(/^javascript:\s*addall(\d+)\s*\(\s*\)\s*;?\s*$/i);
    return m ? m[1] : null;
  };

  function findAnchor(event) {
    const path = typeof event.composedPath === "function" ? event.composedPath() : [];
    for (const node of path) {
      if (node && node.tagName === "A") return node;
    }
    let el = event.target;
    while (el && el !== document.documentElement) {
      if (el.tagName === "A") return el;
      el = el.parentElement;
    }
    return null;
  }

  function toast(text, bad = false) {
    try {
      const old = document.getElementById("__dimomule_toast");
      if (old) old.remove();
      const box = document.createElement("div");
      box.id = "__dimomule_toast";
      box.textContent = text;
      Object.assign(box.style, {
        position: "fixed",
        right: "18px",
        bottom: "18px",
        zIndex: "2147483647",
        padding: "10px 14px",
        borderRadius: "8px",
        font: "13px Arial, sans-serif",
        background: bad ? "#7a1f1f" : "#202124",
        color: "#fff",
        boxShadow: "0 2px 10px rgba(0,0,0,.35)"
      });
      (document.body || document.documentElement).appendChild(box);
      setTimeout(() => box.remove(), 3200);
    } catch (_) {}
  }

  function openOne(url) {
    return new Promise(resolve => {
      chrome.runtime.sendMessage({type: "OPEN_ED2K_NATIVE", url}, response => {
        if (chrome.runtime.lastError) {
          console.error("[Dimomule]", chrome.runtime.lastError.message);
          resolve(false);
          return;
        }
        if (!response || !response.ok) {
          console.error("[Dimomule] apertura fallita", response);
          resolve(false);
          return;
        }
        resolve(true);
      });
    });
  }

  const wait = ms => new Promise(resolve => setTimeout(resolve, ms));

  async function openBatch(urls) {
    const clean = [...new Set(urls.filter(isEd2k).map(x => x.trim()))];
    if (!clean.length) {
      toast("Dimomule: nessun link eD2K trovato", true);
      return;
    }

    toast(`Dimomule: invio ${clean.length} link a eMule...`);
    let ok = 0;
    for (const url of clean) {
      if (await openOne(url)) ok++;
      await wait(250);
    }
    if (ok === clean.length)
      toast(`Dimomule: ${ok} link inviati a eMule`);
    else
      toast(`Dimomule: inviati ${ok} di ${clean.length} link`, true);
  }

  function intercept(event) {
    if (!event.isTrusted || event.defaultPrevented) return;
    const anchor = findAnchor(event);
    if (!anchor) return;

    const href = anchor.getAttribute("href") || anchor.href || "";

    if (isEd2k(href)) {
      event.preventDefault();
      event.stopImmediatePropagation();
      openOne(href.trim());
      return;
    }

    const addAllId = parseAddAll(href);
    if (addAllId) {
      event.preventDefault();
      event.stopImmediatePropagation();

      const requestId = (crypto.randomUUID ? crypto.randomUUID() :
        `${Date.now()}-${Math.random().toString(16).slice(2)}`);
      pendingAddAll.set(requestId, Date.now());

      window.postMessage({
        marker: MARKER,
        type: "GET_ADDALL",
        id: addAllId,
        requestId
      }, "*");

      setTimeout(() => {
        if (pendingAddAll.delete(requestId))
          toast("Dimomule: impossibile leggere i link multipli dalla pagina", true);
      }, 1800);
    }
  }

  window.addEventListener("message", event => {
    if (event.source !== window) return;
    const data = event.data;
    if (!data || data.marker !== MARKER || data.type !== "ADDALL_RESULT") return;
    if (!pendingAddAll.delete(data.requestId)) return;

    const urls = Array.isArray(data.urls) ? data.urls : [];
    openBatch(urls);
  });

  document.addEventListener("click", intercept, true);
  document.addEventListener("auxclick", event => {
    if (event.button === 1) intercept(event);
  }, true);
})();
