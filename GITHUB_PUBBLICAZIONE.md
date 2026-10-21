# Pubblicazione di Dimomule Personal su GitHub

Questo file e destinato al manutentore di questa fork personale.

## Repository

Questa e una fork personale e indipendente. Gli aggiornamenti si fanno solo su questo repository: non si sincronizza e non si fa merge con il progetto di origine. Ogni modifica proveniente da altre fonti va rivista riga per riga prima di essere integrata.

## Descrizione repository

> Versione personale e ristretta di un'estensione Chrome per Windows che apre i link eD2K in eMule, inclusi i vecchi link multipli addall.

## Topics consigliati

`emule`, `ed2k`, `chrome-extension`, `native-messaging`, `windows`, `manifest-v3`

## Strategia versioni

La versione mostrata agli utenti resta **Dimomule Personal** e il `manifest.json` resta `1.0.0`.
La build e indicata nel file `REVISION.txt` con una revisione progressiva:

- `r001-p1`
- `r001-p2`
- `r001-p3`

L'installer accetta solo valori nel formato `rNNN` oppure `rNNN-pN`.

## Distribuzione

Il pacchetto si ottiene direttamente da questo repository (Code -> Download ZIP oppure `git clone`). Non si pubblicano release con file allegati e non si caricano file eseguibili: il Native Host viene compilato in locale da `INSTALLA_DIMOMULE.cmd` a partire da `_support/NativeHost.cs`.

Se si vuole marcare una build, basta creare un tag su questo repository con lo stesso nome della revisione (per esempio `r001-p1`).

## Valori da non cambiare

- manifest `key` dell'estensione;
- ID Chrome `jipokengmllmldjhfjceeemnnnjeicli`;
- Native Host `it.dimomule_personal.ed2k_opener`;
- cartella `%LOCALAPPDATA%\DimomulePersonal`;
- nome visibile `Dimomule Personal`;
- versione manifest `1.0.0`.

L'installer blocca l'installazione se rileva un cambio accidentale della chiave dell'estensione. La chiave privata corrispondente non e stata conservata e non serve per caricare l'estensione non pacchettizzata.

## Prima di ogni commit

- `node --check` su tutti i file `.js` in `Chrome/`;
- `node tests/validate.test.mjs`;
- se si modifica la validazione dei link, aggiornare lo stesso pattern sia in `Chrome/service-worker.js` sia in `_support/NativeHost.cs` (il test verifica che siano identici);
- aggiornare `REVISION.txt` e la riga `Build:` di `LEGGIMI.txt`.
