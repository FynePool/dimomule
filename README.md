# Dimomule Personal

**Dimomule Personal** collega Google Chrome a eMule su Windows e ripristina l'apertura dei link `ed2k://` che i browser moderni possono bloccare. Supporta inoltre i vecchi pulsanti multipli del tipo `javascript:addall...()` presenti su alcuni siti eD2K.

E una versione personale e piu restrittiva derivata da Dimomule 1.0 build r001 di Dimonium74. Ha un'identita propria (ID Chrome, Native Host e cartella diversi) e puo convivere con un'eventuale installazione dell'originale.

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
3. Apri `chrome://extensions` e attiva **Modalita sviluppatore**.
4. Premi **Carica estensione non pacchettizzata**.
5. Seleziona `%LOCALAPPDATA%\DimomulePersonal\Chrome`.

Il percorso viene copiato negli appunti dall'installer. Chrome deve essere caricato dalla copia stabile in LocalAppData, non dalla cartella temporanea estratta dallo ZIP.

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
- prima installazione del Native Host tramite `INSTALLA_DIMOMULE.cmd`.

## Identita stabile

- Nome: `Dimomule Personal`
- Manifest: `1.0.0`
- ID Chrome: `jipokengmllmldjhfjceeemnnnjeicli`
- Native Host: `it.dimomule_personal.ed2k_opener`
- Cartella: `%LOCALAPPDATA%\DimomulePersonal`

Per evitare di rompere gli aggiornamenti, **questi valori non devono essere cambiati nelle build future**. La chiave privata corrispondente alla `key` del manifest non e stata conservata: non serve per le estensioni non pacchettizzate.
