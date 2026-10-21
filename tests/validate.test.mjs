// Test della validazione dei link eD2K. Eseguire con: node tests/validate.test.mjs
// Carica il vero Chrome/service-worker.js in una sandbox con un oggetto chrome finto
// e verifica che il pattern di _support/NativeHost.cs sia identico a quello JS.
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import vm from "node:vm";
import assert from "node:assert/strict";

const root = fileURLToPath(new URL("..", import.meta.url));
const swSource = readFileSync(root + "Chrome/service-worker.js", "utf8");
const csSource = readFileSync(root + "_support/NativeHost.cs", "utf8");

const sandbox = {
  chrome: { runtime: { onMessage: { addListener() {} }, sendNativeMessage() {} } }
};
vm.createContext(sandbox);
vm.runInContext(swSource, sandbox);
const validEd2k = sandbox.validEd2k;
assert.equal(typeof validEd2k, "function", "validEd2k non trovata nel service worker");

let failures = 0;
let count = 0;
function check(expected, url, label) {
  count++;
  const got = validEd2k(url);
  if (got !== expected) {
    failures++;
    console.error(`FAIL [atteso ${expected ? "valido" : "non valido"}] ${label}: ${JSON.stringify(url).slice(0, 160)}`);
  }
}

// Stesso pattern nei due file.
const jsPattern = swSource.match(/String\.raw`([^`]*)`/)[1];
const csPattern = csSource.match(/Ed2kPattern = @"([^"]*)"/)[1];
count++;
if (jsPattern !== csPattern) {
  failures++;
  console.error("FAIL pattern JS e C# diversi");
}

const H = "0123456789ABCDEF0123456789ABCDEF";
const h = "0123456789abcdef0123456789abcdef";
const AICH = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

// Link validi.
const valid = [
  [`ed2k://|file|ubuntu-24.04-desktop-amd64.iso|6114656256|${H}|/`, "file base"],
  [`ed2k://|file|Libro%20di%20prova.pdf|1048576|${h}|/`, "file, hash minuscolo"],
  [`ED2K://|file|nome.avi|734003200|${H}|/`, "schema maiuscolo"],
  [`ed2k://|file|Nome con spazi [ITA].mkv|123|${H}|/`, "nome con spazi e parentesi"],
  [`ed2k://|file|Città è più.mp3|5000000|${H}|/`, "nome con caratteri accentati"],
  [`ed2k://|file|a.iso|1|${H}|h=${AICH}|/`, "con hash AICH"],
  [`ed2k://|file|a.iso|19000000|${H}|p=${H}:${h}|/`, "con hashset p="],
  [`ed2k://|file|a.iso|1000|${H}|s=http://mirror.example.org/a.iso|/`, "con sorgente web s="],
  [`ed2k://|file|a.iso|1000|${H}|h=${AICH}|p=${H}|/`, "h= e p= insieme"],
  [`ed2k://|file|a.iso|1000|${H}|/|sources,192.168.1.10:4662|/`, "con sources IP"],
  [`ed2k://|file|a.iso|1000|${H}|/|sources,10.0.0.1:4662,peer.example.net:4672|/`, "sources multiple"],
  [`ed2k://|server|176.123.5.89|4725|/`, "server IP"],
  [`ed2k://|server|server.example.net|4242|/`, "server hostname"],
  [`ed2k://|serverlist|http://upd.emule-security.org/server.met|/`, "serverlist http"],
  [`ed2k://|serverlist|https://example.org/list/server.met|/`, "serverlist https"],
  [`  ed2k://|file|a.iso|1000|${H}|/  `, "spazi esterni (rimossi da trim)"],
];

// Link malformati o malevoli.
const invalid = [
  ["", "stringa vuota"],
  ["ed2k://", "solo schema"],
  ["ed2k://|file|a.iso|1000|/", "manca l'hash"],
  [`ed2k://|file|a.iso|1000|${H}|`, "manca la barra finale"],
  [`ed2k://|file|a.iso|1000|${H}`, "troncato"],
  [`ed2k://|file||1000|${H}|/`, "nome vuoto"],
  [`ed2k://|file|a.iso|abc|${H}|/`, "dimensione non numerica"],
  [`ed2k://|file|a.iso|0|${H}|/`, "dimensione zero"],
  [`ed2k://|file|a.iso|-5|${H}|/`, "dimensione negativa"],
  [`ed2k://|file|a.iso|12345678901234567|${H}|/`, "dimensione oltre 16 cifre"],
  [`ed2k://|file|a.iso|١٢٣|${H}|/`, "cifre non ASCII nella dimensione"],
  [`ed2k://|file|a.iso|1000|0123456789ABCDEF0123456789ABCDE|/`, "hash di 31 caratteri"],
  [`ed2k://|file|a.iso|1000|${H}0|/`, "hash di 33 caratteri"],
  [`ed2k://|file|a.iso|1000|0123456789ABCDEF0123456789ABCDEG|/`, "hash non esadecimale"],
  [`ed2k://|file|a"b.iso|1000|${H}|/`, "virgolette nel nome"],
  [`ed2k://|file|a.iso|1000|${H}|/" --evil`, "virgolette e argomenti aggiunti"],
  [`ed2k://|file|a.iso|1000|${H}|/\r\nX`, "CRLF in coda"],
  [`ed2k://|file|a\n.iso|1000|${H}|/`, "a capo nel nome"],
  [`ed2k://|file|a\u0000.iso|1000|${H}|/`, "NUL nel nome"],
  [`ed2k://|file|a\t.iso|1000|${H}|/`, "tab nel nome"],
  [`ed2k://|file|a\u007f.iso|1000|${H}|/`, "DEL nel nome"],
  [`ed2k://|file|a.iso|1000|${H}|h=SHORT|/`, "AICH troppo corto"],
  [`ed2k://|file|a.iso|1000|${H}|x=foo|/`, "parametro sconosciuto"],
  [`ed2k://|file|a.iso|1000|${H}|s=javascript:alert(1)|/`, "s= non http"],
  [`ed2k://|file|a.iso|1000|${H}|s=file:///C:/Windows/calc.exe|/`, "s= file://"],
  [`ed2k://|file|a.iso|1000|${H}|/|sources,1.2.3.4|/`, "sources senza porta"],
  [`ed2k://|file|a.iso|1000|${H}|/|sources,|/`, "sources vuoto"],
  [`ed2k://|file|a.iso|1000|${H}|/extra`, "testo dopo la barra finale"],
  ["ed2k://|server|1.2.3.4|/", "server senza porta"],
  ["ed2k://|server|1.2.3.4|123456|/", "porta server di 6 cifre"],
  ["ed2k://|server|-bad-.host|4661|/", "hostname non valido"],
  ["ed2k://|server|1.2.3.4|4661|", "server senza barra finale"],
  ["ed2k://|serverlist|ftp://example.org/server.met|/", "serverlist non http"],
  ["ed2k://|serverlist|javascript:alert(1)|/", "serverlist javascript"],
  ["ed2k://|serverlist|http://exa mple.org/s.met|/", "serverlist con spazio"],
  ["ed2k://|search|ubuntu|/", "tipo sconosciuto"],
  [`ed2k://|FILE|a.iso|1000|${H}|/`, "parola chiave maiuscola"],
  [`ed2k:|file|a.iso|1000|${H}|/`, "schema incompleto"],
  [`http://evil.example/ed2k://|file|a.iso|1000|${H}|/`, "schema diverso"],
  [`javascript:alert(1)//ed2k://|file|a.iso|1000|${H}|/`, "javascript: con ed2k dentro"],
  [`ed2k://|file|${"a".repeat(33000)}|1000|${H}|/`, "oltre 32768 caratteri"],
];

// --dump: stampa i casi in JSON (solo ASCII) per tests/nativehost.test.ps1.
if (process.argv.includes("--dump")) {
  const cases = [
    ...valid.map(([url, label]) => ({ url, label, expected: true })),
    ...invalid.map(([url, label]) => ({ url, label, expected: false })),
  ];
  const json = JSON.stringify(cases).replace(/[\u007f-￿]/g,
    c => "\\u" + c.charCodeAt(0).toString(16).padStart(4, "0"));
  process.stdout.write(json + "\n");
  process.exit(0);
}

for (const [url, label] of valid) check(true, url, label);
for (const [url, label] of invalid) check(false, url, label);

// Valori non stringa.
for (const v of [null, undefined, 42, {}, ["ed2k://"]]) check(false, v, `tipo ${typeof v}`);

if (failures) {
  console.error(`\n${failures} test falliti su ${count}`);
  process.exit(1);
}
console.log(`OK: ${count} controlli superati (${valid.length} validi, ${invalid.length} non validi, pattern JS = C#)`);
