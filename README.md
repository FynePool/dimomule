# Dimomule Personal

**Dimomule Personal** collega Google Chrome a eMule su Windows e ripristina l'apertura dei link `ed2k://` che i browser moderni possono bloccare. Supporta inoltre i vecchi pulsanti multipli del tipo `javascript:addall...()` presenti su alcuni siti eD2K.

E una versione personale e piu restrittiva derivata da Dimomule 1.0 build r001 di Dimonium74. Ha un'identita propria (ID Chrome, Native Host e cartella diversi) e puo convivere con un'eventuale installazione dell'originale.

## Download

Scarica questo repository (pulsante **Code -> Download ZIP** oppure `git clone`). Il pacchetto non contiene file eseguibili precompilati: il Native Host viene compilato in locale dall'installer a partire da `_support/NativeHost.cs`.

## Prima installazione

1. Estrai completamente lo ZIP (o usa la cartella clonata).
2. Esegui `INSTALLA_DIMOMULE.cmd`.
3. Apri `chrome://extensions` e attiva **Modalita sviluppatore**.
4. Premi **Carica estensione non pacchettizzata**.
5. Seleziona `%LOCALAPPDATA%\DimomulePersonal\Chrome`.

Il percorso viene copiato negli appunti dall'installer. Chrome deve essere caricato dalla copia stabile in LocalAppData, non dalla cartella temporanea estratta dallo ZIP.

## Aggiornamenti

Le build successive mantengono il nome visibile **Dimomule Personal**, lo stesso ID dell'estensione e la stessa cartella stabile. Le build sono identificate internamente come `r001-p1`, `r001-p2` e cosi via (file `REVISION.txt`).

Per aggiornare, scarica di nuovo il repository (o esegui `git pull`) ed esegui di nuovo `INSTALLA_DIMOMULE.cmd`. **Non devi ricaricare l'estensione non pacchettizzata da zero.** Se necessario, vai in `chrome://extensions` e premi **Ricarica** sulla scheda Dimomule Personal.

## Siti abilitati

L'estensione e attiva soltanto su questi domini e sui loro sottodomini, in HTTP e HTTPS:

- `ddunlimited.net`
- `emulelinks.it`
- `ildragonero2.info`

Sugli altri siti non viene caricato alcuno script e i link `ed2k://` non vengono intercettati. L'estensione non chiede `host_permissions`.

### Aggiungere un dominio

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
