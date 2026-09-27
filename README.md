# Dimomule 1.0

**Dimomule** collega Google Chrome a eMule su Windows e ripristina l'apertura dei link `ed2k://` che i browser moderni possono bloccare. Supporta inoltre i vecchi pulsanti multipli del tipo `javascript:addall...()` presenti su alcuni siti eD2K.

## Download

Scarica **`Dimomule_1.0.zip` dalla release piu recente** nella sezione **Releases** di questo repository. Per l'installazione normale non usare gli archivi automatici **Source code (zip/tar.gz)** generati da GitHub.

## Prima installazione

1. Estrai completamente `Dimomule_1.0.zip`.
2. Esegui `INSTALLA_DIMOMULE.cmd`.
3. Apri `chrome://extensions` e attiva **Modalita sviluppatore**.
4. Premi **Carica estensione non pacchettizzata**.
5. Seleziona `%LOCALAPPDATA%\Dimomule\Chrome`.

Il percorso viene copiato negli appunti dall'installer. Chrome deve essere caricato dalla copia stabile in LocalAppData, non dalla cartella temporanea estratta dallo ZIP.

## Aggiornamenti

Le future release mantengono il nome visibile **Dimomule 1.0**, lo stesso ID dell'estensione e la stessa cartella stabile. Le build sono identificate internamente come `r001`, `r002`, `r003` e cosi via.

Per aggiornare, scarica il nuovo `Dimomule_1.0.zip`, estrailo ed esegui di nuovo `INSTALLA_DIMOMULE.cmd`. **Non devi ricaricare l'estensione non pacchettizzata da zero.** Se necessario, vai in `chrome://extensions` e premi **Ricarica** sulla scheda Dimomule.

## Come funziona

`Pagina web -> estensione Dimomule -> Chrome Native Messaging -> Windows -> programma associato a ed2k://`

Dimomule non impone il percorso di eMule: usa l'associazione del protocollo eD2K gia registrata in Windows.

## Sicurezza e privacy

Dimomule non raccoglie telemetria e non invia la cronologia di navigazione a server esterni. Il Native Host accetta soltanto messaggi provenienti dall'ID ufficiale dell'estensione e valida gli URL `ed2k://` prima di passarli a Windows.

L'installer non modifica il file Windows `hosts`, non cambia l'associazione `ed2k://` e non cancella file di Windows. Gli aggiornamenti usano staging, backup e rollback dei soli file Dimomule conosciuti.

## Diagnostica

Esegui `VERIFICA_DIMOMULE.cmd` per controllare la configurazione locale. Cliccando sull'icona di Dimomule in Chrome si apre inoltre il pannello informativo con accesso alla guida completa.

## Requisiti

- Windows con Google Chrome;
- eMule o mod compatibile gia configurata per il protocollo `ed2k://`;
- prima installazione del Native Host tramite `INSTALLA_DIMOMULE.cmd`.

## Identita stabile

- Nome: `Dimomule 1.0`
- Manifest: `1.0.0`
- ID Chrome: `mihhpbnljinclnfipcadonlnnnnngkbk`
- Native Host: `it.dimomule.ed2k_opener`
- Cartella: `%LOCALAPPDATA%\Dimomule`

Per evitare di rompere gli aggiornamenti, **questi valori non devono essere cambiati nelle release future**.
