(() => {
  const MARKER = "DIMOMULE_1_0_ADDALL";
  const isEd2k = value =>
    typeof value === "string" && /^ed2k:\/\//i.test(value.trim());

  function collectFromArrayName(name) {
    try {
      const value = window[name];
      if (!value) return [];
      const items = Array.isArray(value) ? value :
        (typeof value.length === "number" ? Array.from(value) : []);
      return items.filter(isEd2k).map(x => x.trim());
    } catch (_) {
      return [];
    }
  }

  function collectFromScripts(id) {
    const out = [];
    try {
      for (const script of document.scripts) {
        const text = script.textContent || "";
        if (!text || (!text.includes(`addall${id}`) && !text.includes(`filearray${id}`)))
          continue;
        const rx = /["'](ed2k:\/\/[^"'\r\n]+)["']/ig;
        let m;
        while ((m = rx.exec(text)) !== null) {
          if (isEd2k(m[1])) out.push(m[1].trim());
        }
      }
    } catch (_) {}
    return out;
  }

  function collect(id) {
    let urls = collectFromArrayName(`filearray${id}`);
    if (urls.length) return urls;

    // Fallback: ricava dal sorgente della funzione il nome dell'array usato.
    try {
      const fn = window[`addall${id}`];
      if (typeof fn === "function") {
        const src = Function.prototype.toString.call(fn);
        const names = [...src.matchAll(/\b(filearray\d+)\b/ig)].map(m => m[1]);
        for (const name of names) {
          urls = collectFromArrayName(name);
          if (urls.length) return urls;
        }
      }
    } catch (_) {}

    // Ultimo fallback per vecchie pagine che dichiarano tutto inline.
    return collectFromScripts(id);
  }

  window.addEventListener("message", event => {
    if (event.source !== window) return;
    const data = event.data;
    if (!data || data.marker !== MARKER || data.type !== "GET_ADDALL") return;
    if (!/^\d+$/.test(String(data.id || ""))) return;

    const urls = [...new Set(collect(String(data.id)))].slice(0, 2000);
    window.postMessage({
      marker: MARKER,
      type: "ADDALL_RESULT",
      requestId: data.requestId,
      urls
    }, "*");
  });
})();
