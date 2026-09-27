const HOST = "it.dimomule.ed2k_opener";

function validEd2k(value) {
  if (typeof value !== "string") return false;
  const s = value.trim();
  return /^ed2k:\/\//i.test(s) && s.length <= 32768 && !/[\r\n\0]/.test(s);
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

