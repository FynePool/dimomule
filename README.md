# Dimomule Personal

**Dimomule Personal** connects Google Chrome to eMule on Windows and restores opening `ed2k://` links, which modern browsers may block. It also supports the legacy "add all" buttons (`javascript:addall...()`) found on some eD2K sites.

It is a personal, stricter fork of Dimomule 1.0 build r001 by Dimonium74, with its own identity (different Chrome ID, Native Host and folder), so it can live alongside an install of the original. It sends no data to external servers, only accepts well-formed eD2K links, and runs only on the sites you choose.

<details>
<summary><strong>English</strong></summary>

## Download

There are two ways to install. Use only one of them.

- **Setup (recommended):** download `DimomulePersonal-Setup-rXXX.exe` from the **Releases** section of this repository. It is built by GitHub Actions from this source code; `SHA256SUMS.txt` next to it holds the hash to check it.
- **ZIP package:** download the repository (**Code -> Download ZIP** or `git clone`). In this case the Native Host is compiled locally by the installer from `_support/NativeHost.cs`.

The repository contains no executable files.

## Installing with the setup

1. Run `DimomulePersonal-Setup-rXXX.exe`. The file is not digitally signed, so Windows may show "Windows protected your PC": choose **More info -> Run anyway**.
2. On the **Siti abilitati** (enabled sites) page choose:
   - **Tutti i domini** (all domains): the extension works on any HTTP and HTTPS site;
   - **Solo i domini selezionati** (selected domains only): enter one domain per line (for example `site.com`). Subdomains are included; if you paste a full address such as `https://www.site.com/forum/`, only `site.com` is kept.
3. Finish the installation. The last page explains the steps to do in Chrome (see below) and copies the folder path to the clipboard.

The setup installs for the current user only, without administrator rights, and is uninstalled from **Settings -> Apps** (or with `unins000.exe` in the install folder).

For an unattended install: `DimomulePersonal-Setup-rXXX.exe /VERYSILENT /DOMINI=site1.com,site2.net` (or `/DOMINI=tutti` for all domains).

The setup is in Italian.

## First install with the ZIP package

1. Fully extract the ZIP (or use the cloned folder).
2. Run `INSTALLA_DIMOMULE.cmd`.
3. Load the extension in Chrome as described below.

Chrome must load the stable copy in LocalAppData, not the temporary folder extracted from the ZIP.

## Loading the extension in Chrome

Chrome does not let any program install an extension that does not come from the Chrome Web Store, so this step must be done by hand, once, with either method:

1. open `chrome://extensions`;
2. turn on **Developer mode** (top right);
3. click **Load unpacked**;
4. select `%LOCALAPPDATA%\DimomulePersonal\Chrome` (the path is in the clipboard).

## Updates

Later builds keep the visible name **Dimomule Personal**, the same extension ID and the same stable folder. Builds are numbered internally as `r001-p1`, `r001-p2` and so on (`REVISION.txt`).

To update with the setup, run the new `DimomulePersonal-Setup-rXXX.exe`: it offers the sites chosen last time. With the ZIP package, download the repository again (or `git pull`) and run `INSTALLA_DIMOMULE.cmd` again. **You do not need to load the unpacked extension again.** If needed, open `chrome://extensions` and click **Reload** on the Dimomule Personal card.

## Enabled sites

With the setup, sites are chosen during installation; to change them, run the setup again and then click **Reload** in `chrome://extensions`.

With the ZIP package the extension is active only on these domains and their subdomains, over HTTP and HTTPS:

- `ddunlimited.net`
- `emulelinks.it`
- `ildragonero2.info`

On other sites no script is loaded and `ed2k://` links are not intercepted. The extension does not request `host_permissions`.

### Adding a domain (ZIP package)

The only file to edit is `Chrome/manifest.json`.

1. In **both** `content_scripts` blocks, add a line like this to the `matches` list:

   ```json
   "*://*.newdomain.tld/*"
   ```

   `*://` covers HTTP and HTTPS; `*.newdomain.tld` covers the domain itself and all its subdomains. The two lists must stay identical.
2. Run `INSTALLA_DIMOMULE.cmd` again; it copies the updated manifest to the stable folder.
3. Open `chrome://extensions` and click **Reload** on the Dimomule Personal card.

## How it works

`Web page -> Dimomule Personal extension -> Chrome Native Messaging -> Windows -> program associated with ed2k://`

Dimomule does not hard-code the eMule path: it uses the eD2K protocol association already registered in Windows.

## Multiple links

Before sending an "add all" list, the extension asks for confirmation and shows the number of links (in Italian, for example *Inviare 37 link a eMule?*). If you cancel, nothing is sent. At most **500** links are sent per button; if the page has more, the confirmation and the on-screen message say so and only the first 500 are sent.

## Security and privacy

Dimomule collects no telemetry and does not send browsing history to external servers. The Native Host only accepts messages from this extension's ID.

Both the extension (`Chrome/service-worker.js`) and the Native Host (`_support/NativeHost.cs`) accept only eD2K links in the real format, with the same pattern:

- `ed2k://|file|<name>|<size>|<32 hex digit MD4 hash>|[h=...|][p=...|][s=http(s)://...|]/[|sources,host:port,...|/]`
- `ed2k://|server|<IP or host>|<port>|/`
- `ed2k://|serverlist|<http or https URL>|/`

Links with control characters (newline, tab, NUL...) or double quotes, and links longer than 32768 characters, are rejected.

The installer does not modify the Windows `hosts` file, does not change the `ed2k://` association and does not delete Windows files. Updates use staging, backup and rollback of known Dimomule files only.

## Tests

`node tests/validate.test.mjs` checks link validation against a list of valid and malformed links and checks that the pattern in `NativeHost.cs` is identical to the service worker's. No packages need to be installed.

On Windows, GitHub Actions (`.github/workflows/release.yml`) also runs:

- `tests/nativehost.test.ps1`: the same cases fed to the compiled Native Host;
- `tests/installer.test.ps1`: unattended installs with several domain choices, checks of manifest and registry, uninstall.

## Diagnostics

Run `VERIFICA_DIMOMULE.cmd` to check the local setup. Clicking the Dimomule Personal icon in Chrome also opens the info panel, with a link to the full guide (in Italian).

## Requirements

- Windows with Google Chrome;
- eMule or a compatible mod already registered for the `ed2k://` protocol;
- Native Host installed with the setup or with `INSTALLA_DIMOMULE.cmd`.

## Stable identity

- Name: `Dimomule Personal`
- Manifest: `1.0.0`
- Chrome ID: `jipokengmllmldjhfjceeemnnnjeicli`
- Native Host: `it.dimomule_personal.ed2k_opener`
- Folder: `%LOCALAPPDATA%\DimomulePersonal`

To avoid breaking updates, **these values must not change in future builds**. The private key matching the manifest `key` was not kept: it is not needed for unpacked extensions.

</details>

<details>
<summary><strong>Italiano</strong></summary>

## Download

Ci sono due modi per installare. Usane uno solo.

- **Setup (consigliato):** scarica `DimomulePersonal-Setup-rXXX.exe` dalla sezione **Releases** di questo repository. Il file viene compilato da GitHub Actions a partire da questo codice; accanto c'e `SHA256SUMS.txt` con l'hash per controllarlo.
- **Pacchetto ZIP:** scarica il repository (pulsante **Code -> Download ZIP** oppure `git clone`). In questo caso il Native Host viene compilato in locale dall'installer a partire da `_support/NativeHost.cs`.

Nel repository non ci sono file eseguibili.

## Installazione con il setup

1. Esegui `DimomulePersonal-Setup-rXXX.exe`. Il file non e firmato digitalmente, quindi Windows puo mostrare "Windows ha protetto il PC": scegli **Ulteriori informazioni -> Esegui comunque**.
2. Nella pagina **Siti abilitati** scegli:
   - **Tutti i domini**: l'estensione funziona su qualsiasi sito HTTP e HTTPS;
   - **Solo i domini selezionati**: scrivi un dominio per riga (per esempio `sito.it`). Sono inclusi i sottodomini; se incolli un indirizzo completo come `https://www.sito.it/forum/` viene tenuto solo `sito.it`.
3. Completa l'installazione. L'ultima pagina spiega i passaggi da fare in Chrome (sotto) e il percorso della cartella viene copiato negli appunti.

Il setup installa per il solo utente corrente, senza permessi di amministratore, e si disinstalla da **Impostazioni -> App** (oppure con `unins000.exe` nella cartella di installazione).

Per un'installazione senza finestre: `DimomulePersonal-Setup-rXXX.exe /VERYSILENT /DOMINI=sito1.it,sito2.net` (oppure `/DOMINI=tutti`).

## Prima installazione con il pacchetto ZIP

1. Estrai completamente lo ZIP (o usa la cartella clonata).
2. Esegui `INSTALLA_DIMOMULE.cmd`.
3. Carica l'estensione in Chrome come spiegato sotto.

Chrome deve essere caricato dalla copia stabile in LocalAppData, non dalla cartella temporanea estratta dallo ZIP.

## Caricare l'estensione in Chrome

Chrome non permette a nessun programma di installare da solo un'estensione che non viene dal Chrome Web Store, quindi questo passaggio va fatto a mano una sola volta, con entrambi i metodi:

1. apri `chrome://extensions`;
2. attiva **Modalita sviluppatore** (in alto a destra);
3. premi **Carica estensione non pacchettizzata**;
4. seleziona `%LOCALAPPDATA%\DimomulePersonal\Chrome` (il percorso e negli appunti).

## Aggiornamenti

Le build successive mantengono il nome visibile **Dimomule Personal**, lo stesso ID dell'estensione e la stessa cartella stabile. Le build sono identificate internamente come `r001-p1`, `r001-p2` e cosi via (file `REVISION.txt`).

Per aggiornare con il setup, esegui il nuovo `DimomulePersonal-Setup-rXXX.exe`: ripropone i siti scelti la volta precedente. Con il pacchetto ZIP, scarica di nuovo il repository (o esegui `git pull`) ed esegui di nuovo `INSTALLA_DIMOMULE.cmd`. **Non devi ricaricare l'estensione non pacchettizzata da zero.** Se necessario, vai in `chrome://extensions` e premi **Ricarica** sulla scheda Dimomule Personal.

## Siti abilitati

Con il setup i siti si scelgono durante l'installazione; per cambiarli basta rieseguire il setup e poi premere **Ricarica** in `chrome://extensions`.

Con il pacchetto ZIP l'estensione e attiva soltanto su questi domini e sui loro sottodomini, in HTTP e HTTPS:

- `ddunlimited.net`
- `emulelinks.it`
- `ildragonero2.info`

Sugli altri siti non viene caricato alcuno script e i link `ed2k://` non vengono intercettati. L'estensione non chiede `host_permissions`.

### Aggiungere un dominio (pacchetto ZIP)

L'unico punto da modificare e `Chrome/manifest.json`.

1. Nei **due** blocchi `content_scripts` aggiungi alla lista `matches` una riga come:

   ```json
   "*://*.nuovodominio.tld/*"
   ```

   `*://` copre HTTP e HTTPS; `*.nuovodominio.tld` copre il dominio stesso e tutti i sottodomini. Le due liste devono restare identiche.
2. Esegui di nuovo `INSTALLA_DIMOMULE.cmd`, che copia il manifest aggiornato nella cartella stabile.
3. Apri `chrome://extensions` e premi **Ricarica** sulla scheda Dimomule Personal.

## Come funziona

`Pagina web -> estensione Dimomule Personal -> Chrome Native Messaging -> Windows -> programma associato a ed2k://`

Dimomule non impone il percorso di eMule: usa l'associazione del protocollo eD2K gia registrata in Windows.

## Link multipli

Prima di inviare un elenco "Aggiungi tutti" l'estensione chiede conferma indicando il numero di link (per esempio *Inviare 37 link a eMule?*). Se annulli non viene inviato nulla. Per ogni pulsante vengono inviati al massimo **500** link; se la pagina ne contiene di piu, la richiesta di conferma e il messaggio a schermo lo segnalano e vengono inviati solo i primi 500.

## Sicurezza e privacy

Dimomule non raccoglie telemetria e non invia la cronologia di navigazione a server esterni. Il Native Host accetta soltanto messaggi provenienti dall'ID di questa estensione.

Sia l'estensione (`Chrome/service-worker.js`) sia il Native Host (`_support/NativeHost.cs`) accettano soltanto link eD2K nel formato reale, con lo stesso pattern:

- `ed2k://|file|<nome>|<dimensione>|<hash MD4 di 32 cifre esadecimali>|[h=...|][p=...|][s=http(s)://...|]/[|sources,host:porta,...|/]`
- `ed2k://|server|<IP o host>|<porta>|/`
- `ed2k://|serverlist|<URL http o https>|/`

Vengono rifiutati i link con caratteri di controllo (a capo, tab, NUL...) o virgolette doppie, e quelli piu lunghi di 32768 caratteri.

L'installer non modifica il file Windows `hosts`, non cambia l'associazione `ed2k://` e non cancella file di Windows. Gli aggiornamenti usano staging, backup e rollback dei soli file Dimomule conosciuti.

## Test

`node tests/validate.test.mjs` verifica la validazione dei link su un elenco di link validi e malformati e controlla che il pattern di `NativeHost.cs` sia identico a quello del service worker. Non serve installare pacchetti.

Su Windows, GitHub Actions (`.github/workflows/release.yml`) esegue anche:

- `tests/nativehost.test.ps1`: gli stessi casi passati al Native Host compilato;
- `tests/installer.test.ps1`: installazione silenziosa con varie scelte di domini, controllo di manifest e registro, disinstallazione.

## Diagnostica

Esegui `VERIFICA_DIMOMULE.cmd` per controllare la configurazione locale. Cliccando sull'icona di Dimomule Personal in Chrome si apre inoltre il pannello informativo con accesso alla guida completa.

## Requisiti

- Windows con Google Chrome;
- eMule o mod compatibile gia configurata per il protocollo `ed2k://`;
- Native Host installato con il setup oppure con `INSTALLA_DIMOMULE.cmd`.

## Identita stabile

- Nome: `Dimomule Personal`
- Manifest: `1.0.0`
- ID Chrome: `jipokengmllmldjhfjceeemnnnjeicli`
- Native Host: `it.dimomule_personal.ed2k_opener`
- Cartella: `%LOCALAPPDATA%\DimomulePersonal`

Per evitare di rompere gli aggiornamenti, **questi valori non devono essere cambiati nelle build future**. La chiave privata corrispondente alla `key` del manifest non e stata conservata: non serve per le estensioni non pacchettizzate.

</details>
