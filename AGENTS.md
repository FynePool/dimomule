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

Due strade, entrambe da questo repository:

- **Setup:** `DimomulePersonal-Setup-rXXX.exe`, allegato alle release di questo repository insieme a `SHA256SUMS.txt`.
- **Pacchetto ZIP:** il repository stesso (Code -> Download ZIP oppure `git clone`), con `install.cmd`.

Nel repository non si committano file eseguibili (`build/` e `dist/` sono in `.gitignore`). Il setup viene compilato solo da GitHub Actions (`.github/workflows/release.yml`):

1. test Node della validazione;
2. compilazione di `_support/NativeHost.cs` con il compilatore C# di .NET Framework;
3. test del Native Host compilato con gli stessi casi del test Node;
4. compilazione di `installer/DimomulePersonal.iss` con Inno Setup;
5. installazione silenziosa di prova con varie scelte di domini, controllo di manifest e registro, disinstallazione;
6. calcolo dell'hash SHA-256.

Il workflow gira su ogni pull request e su `main`; il risultato e scaricabile come artifact dalla pagina della run.

## Pubblicare una release

1. Aggiorna `REVISION.txt` (per esempio `r001-p3`) e la riga `Build:` di `user-guide.txt`, poi fai merge su `main`.
2. Crea e invia un tag con lo stesso nome:

   ```
   git tag r001-p3
   git push origin r001-p3
   ```

3. GitHub Actions compila, verifica e crea la release `r001-p3` con il setup e `SHA256SUMS.txt`. Se il tag non coincide con `REVISION.txt` la build si ferma.

Il setup non e firmato digitalmente: al primo avvio Windows SmartScreen mostra un avviso.

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
- aggiornare `REVISION.txt` e la riga `Build:` di `user-guide.txt`;
- se si modifica il formato di `Chrome/manifest.json` vicino alle liste `"matches"`, verificare che il setup le trovi ancora (il test del setup in GitHub Actions lo controlla).
