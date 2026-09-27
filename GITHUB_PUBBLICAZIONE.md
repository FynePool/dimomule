# Pubblicazione di Dimomule su GitHub

Questo file e destinato al manutentore del progetto.

## Nome repository consigliato

`Dimomule`

## Descrizione repository

> Estensione Chrome per Windows che ripristina l'apertura dei link eD2K in eMule, inclusi i vecchi link multipli addall.

## Topics consigliati

`emule`, `ed2k`, `chrome-extension`, `native-messaging`, `windows`, `manifest-v3`

## Strategia versioni

La versione mostrata agli utenti resta **Dimomule 1.0** e il `manifest.json` resta `1.0.0`.
Le release GitHub usano invece una revisione progressiva:

- `v1.0-r001`
- `v1.0-r002`
- `v1.0-r003`

Il file allegato alla release deve mantenere SEMPRE lo stesso nome:

`Dimomule_1.0.zip`

In questo modo il progetto conserva un'identita stabile e ogni nuova release puo sostituire la precedente senza obbligare gli utenti a ricaricare l'estensione in Chrome.

## Valori da non cambiare

- manifest `key` dell'estensione;
- ID Chrome `mihhpbnljinclnfipcadonlnnnnngkbk`;
- Native Host `it.dimomule.ed2k_opener`;
- cartella `%LOCALAPPDATA%\Dimomule`;
- nome visibile `Dimomule 1.0`;
- versione manifest `1.0.0`.

L'installer blocca l'installazione se rileva un cambio accidentale della chiave dell'estensione.

## Titolo prima release

`Dimomule 1.0 — build r001`

## Testo prima release

> Prima release pubblica di Dimomule 1.0.
>
> Dimomule ripristina in Google Chrome su Windows l'apertura dei link ed2k:// verso eMule e supporta anche i vecchi link multipli javascript:addall...().
>
> **Prima installazione:** scaricare l'asset Dimomule_1.0.zip, estrarlo, eseguire INSTALLA_DIMOMULE.cmd e caricare una sola volta in chrome://extensions la cartella %LOCALAPPDATA%\Dimomule\Chrome come estensione non pacchettizzata.
>
> **Aggiornamenti successivi:** eseguire il nuovo INSTALLA_DIMOMULE.cmd. Chrome rimane collegato alla stessa cartella e allo stesso ID; non e necessario caricare nuovamente l'estensione. Se necessario, premere Ricarica nella pagina chrome://extensions.
>
> Il pacchetto include installer, disinstaller, diagnostica, Native Host, estensione Chrome, supporto link multipli e guida interna.

## Testo per release future

> Aggiornamento di Dimomule 1.0 — build rXXX.
>
> Scaricare Dimomule_1.0.zip, estrarlo ed eseguire INSTALLA_DIMOMULE.cmd. Non rimuovere e non caricare nuovamente l'estensione in Chrome. Al termine, se necessario, aprire chrome://extensions e premere Ricarica su Dimomule.
>
> Modifiche principali:
> - INSERIRE QUI LE MODIFICHE DELLA BUILD.
