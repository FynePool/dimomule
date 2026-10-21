const HOST = "it.dimomule_personal.ed2k_opener";

// Formato eD2K ammesso: file, server, serverlist. Stesso pattern di _support/NativeHost.cs.
const ED2K_PATTERN = String.raw`^[Ee][Dd]2[Kk]://\|(?:file\|[^|\x00-\x1f\x22\x7f]+\|[1-9][0-9]{0,15}\|[0-9A-Fa-f]{32}\|(?:(?:h=[A-Za-z2-7]{32}|p=[0-9A-Fa-f]{32}(?::[0-9A-Fa-f]{32})*|s=https?://[^|\x00-\x20\x22\x7f]+)\|)*/(?:\|sources(?:,[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*:[0-9]{1,5})+\|/)?|server\|[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*\|[0-9]{1,5}\|/|serverlist\|https?://[^|\x00-\x20\x22\x7f]+\|/)$`;
const ED2K_RE = new RegExp(ED2K_PATTERN);

function validEd2k(value) {
  if (typeof value !== "string") return false;
  const s = value.trim();
  return s.length <= 32768 && !/[\x00-\x1f\x22\x7f]/.test(s) && ED2K_RE.test(s);
}

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (!message || message.type !== "OPEN_ED2K_NATIVE") return;
  if (!sender.tab || !sender.url || !/^https?:\/\//i.test(sender.url)) {
    sendResponse({ok:false,error:"invalid_sender"});
    return;
  }
  const url = String(message.url || "").trim();
  if (!validEd2k(url)) {
    sendResponse({ok:false,error:"invalid_ed2k_url"});
    return;
  }
  chrome.runtime.sendNativeMessage(HOST, {url}, response => {
    if (chrome.runtime.lastError) {
      sendResponse({ok:false,error:chrome.runtime.lastError.message});
      return;
    }
    sendResponse(response || {ok:false,error:"empty_native_response"});
  });
  return true;
});

