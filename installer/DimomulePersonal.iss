; Setup di Dimomule Personal (Inno Setup 6).
; Compilato da .github/workflows/release.yml dopo aver creato build\DimomuleNativeHost.exe
; da _support\NativeHost.cs. Nessun file eseguibile viene salvato nel repository.

#ifndef Revision
  #define Revision "dev"
#endif

#define AppName "Dimomule Personal"
#define ManifestVersion "1.0.0"

[Setup]
AppId={{9A8478E4-713E-4DDC-9B1C-ED8DE90AF977}
AppName={#AppName}
AppVersion={#ManifestVersion}-{#Revision}
AppVerName={#AppName} (build {#Revision})
AppPublisher={#AppName}
DefaultDirName={localappdata}\DimomulePersonal
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
UninstallDisplayName={#AppName}
OutputDir=..\dist
OutputBaseFilename=DimomulePersonal-Setup-{#Revision}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "it"; MessagesFile: "compiler:Languages\Italian.isl"

[Files]
Source: "..\Chrome\*"; DestDir: "{app}\Chrome"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\build\DimomuleNativeHost.exe"; DestDir: "{app}\NativeHost"; Flags: ignoreversion
Source: "..\_support\NativeHost.cs"; DestDir: "{app}\NativeHost"; Flags: ignoreversion
Source: "..\REVISION.txt"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
Root: HKCU; Subkey: "Software\Google\Chrome\NativeMessagingHosts\it.dimomule_personal.ed2k_opener"; ValueType: string; ValueName: ""; ValueData: "{app}\NativeHost\native-host.json"; Flags: uninsdeletekey

[UninstallDelete]
Type: files; Name: "{app}\NativeHost\native-host.json"
Type: files; Name: "{app}\NativeHost\Dimomule.log"
Type: dirifempty; Name: "{app}\NativeHost"
Type: dirifempty; Name: "{app}\Chrome\icons"
Type: dirifempty; Name: "{app}\Chrome"
Type: dirifempty; Name: "{app}"

[Run]
Filename: "{win}\explorer.exe"; Parameters: """{app}\Chrome"""; Description: "Apri la cartella dell'estensione"; Flags: postinstall nowait skipifsilent

[Code]
const
  HostName = 'it.dimomule_personal.ed2k_opener';
  ExtensionId = 'jipokengmllmldjhfjceeemnnnjeicli';
  DefaultDomains = 'ddunlimited.net,emulelinks.it,ildragonero2.info';

var
  DomainsPage: TWizardPage;
  AllRadio, SelectedRadio: TNewRadioButton;
  DomainsMemo: TNewMemo;
  DomainList: TStringList;

procedure UpdateMemoState;
begin
  DomainsMemo.Enabled := SelectedRadio.Checked;
end;

procedure RadioClick(Sender: TObject);
begin
  UpdateMemoState;
end;

procedure InitializeWizard;
var
  Info: TNewStaticText;
  Saved, Param: String;
begin
  DomainList := TStringList.Create;

  DomainsPage := CreateCustomPage(wpWelcome, 'Siti abilitati',
    'Scegli su quali siti Dimomule Personal intercetta i link eD2K.');

  AllRadio := TNewRadioButton.Create(DomainsPage);
  AllRadio.Parent := DomainsPage.Surface;
  AllRadio.Left := 0;
  AllRadio.Top := 0;
  AllRadio.Width := DomainsPage.SurfaceWidth;
  AllRadio.Height := ScaleY(17);
  AllRadio.Caption := 'Tutti i domini (qualsiasi sito HTTP e HTTPS)';
  AllRadio.OnClick := @RadioClick;

  SelectedRadio := TNewRadioButton.Create(DomainsPage);
  SelectedRadio.Parent := DomainsPage.Surface;
  SelectedRadio.Left := 0;
  SelectedRadio.Top := AllRadio.Top + AllRadio.Height + ScaleY(8);
  SelectedRadio.Width := DomainsPage.SurfaceWidth;
  SelectedRadio.Height := ScaleY(17);
  SelectedRadio.Caption := 'Solo i domini selezionati';
  SelectedRadio.OnClick := @RadioClick;

  Info := TNewStaticText.Create(DomainsPage);
  Info.Parent := DomainsPage.Surface;
  Info.Left := ScaleX(18);
  Info.Top := SelectedRadio.Top + SelectedRadio.Height + ScaleY(6);
  Info.Width := DomainsPage.SurfaceWidth - ScaleX(18);
  Info.WordWrap := True;
  Info.Caption := 'Un dominio per riga, per esempio sito.it (senza http:// e senza percorso). ' +
    'Sono inclusi anche tutti i sottodomini.';

  DomainsMemo := TNewMemo.Create(DomainsPage);
  DomainsMemo.Parent := DomainsPage.Surface;
  DomainsMemo.Left := ScaleX(18);
  DomainsMemo.Top := Info.Top + Info.Height + ScaleY(6);
  DomainsMemo.Width := DomainsPage.SurfaceWidth - ScaleX(18);
  DomainsMemo.Height := DomainsPage.SurfaceHeight - DomainsMemo.Top;
  DomainsMemo.ScrollBars := ssVertical;

  // Su un aggiornamento ripropone la scelta precedente.
  Saved := GetPreviousData('Domains', DefaultDomains);
  StringChangeEx(Saved, ',', #13#10, True);
  DomainsMemo.Text := Saved;
  if GetPreviousData('DomainMode', 'selected') = 'all' then
    AllRadio.Checked := True
  else
    SelectedRadio.Checked := True;

  // Installazione da riga di comando: /DOMINI=tutti oppure /DOMINI=sito1.it,sito2.net
  Param := ExpandConstant('{param:DOMINI|}');
  if Lowercase(Param) = 'tutti' then
    AllRadio.Checked := True
  else if Param <> '' then begin
    SelectedRadio.Checked := True;
    StringChangeEx(Param, ',', #13#10, True);
    DomainsMemo.Text := Param;
  end;
  UpdateMemoState;
end;

procedure DeinitializeSetup;
begin
  if DomainList <> nil then DomainList.Free;
end;

// Accetta anche un indirizzo completo (https://www.sito.it/forum/) e ne tiene solo il dominio.
function NormalizeDomain(S: String): String;
var
  P, I: Integer;
begin
  S := Lowercase(Trim(S));
  P := Pos('://', S);
  if P > 0 then S := Copy(S, P + 3, Length(S));
  for I := 1 to Length(S) do
    if (S[I] = '/') or (S[I] = '?') or (S[I] = '#') or (S[I] = ':') then begin
      S := Copy(S, 1, I - 1);
      Break;
    end;
  if Copy(S, 1, 2) = '*.' then S := Copy(S, 3, Length(S));
  if Copy(S, 1, 4) = 'www.' then S := Copy(S, 5, Length(S));
  Result := S;
end;

// Nome di dominio ASCII con almeno un punto; l'ultima parte non puo essere solo numerica.
function IsValidDomain(S: String): Boolean;
var
  I, LabelLen: Integer;
  C: Char;
  LastHasLetter: Boolean;
begin
  Result := False;
  if (Length(S) < 3) or (Length(S) > 253) or (Pos('.', S) = 0) then Exit;
  LabelLen := 0;
  LastHasLetter := False;
  for I := 1 to Length(S) do begin
    C := S[I];
    if C = '.' then begin
      if LabelLen = 0 then Exit;
      if S[I - 1] = '-' then Exit;
      LabelLen := 0;
      LastHasLetter := False;
    end else if ((C >= 'a') and (C <= 'z')) or ((C >= '0') and (C <= '9')) or (C = '-') then begin
      if (C = '-') and (LabelLen = 0) then Exit;
      if (C >= 'a') and (C <= 'z') then LastHasLetter := True;
      LabelLen := LabelLen + 1;
      if LabelLen > 63 then Exit;
    end else
      Exit;
  end;
  if (LabelLen = 0) or (S[Length(S)] = '-') or not LastHasLetter then Exit;
  Result := True;
end;

function ParseDomains(Text: String; List: TStringList; var Bad: String): Boolean;
var
  I: Integer;
  C: Char;
  Tok, D: String;
begin
  List.Clear;
  Bad := '';
  Result := True;
  Text := Text + #10;
  Tok := '';
  for I := 1 to Length(Text) do begin
    C := Text[I];
    if (C = #13) or (C = #10) or (C = ',') or (C = ';') or (C = ' ') or (C = #9) then begin
      if Tok <> '' then begin
        D := NormalizeDomain(Tok);
        if not IsValidDomain(D) then begin
          Bad := Tok;
          Result := False;
          Exit;
        end;
        if List.IndexOf(D) < 0 then List.Add(D);
        Tok := '';
      end;
    end else
      Tok := Tok + C;
  end;
end;

// In modalita silenziosa un /DOMINI non valido va rifiutato qui: se NextButtonClick
// restituisse False il wizard nascosto resterebbe fermo sulla pagina senza mai uscire.
function InitializeSetup(): Boolean;
var
  Handler, Param, Bad: String;
  List: TStringList;
begin
  Result := RegQueryStringValue(HKCR, 'ed2k\shell\open\command', '', Handler) and (Trim(Handler) <> '');
  if not Result then begin
    MsgBox('Windows non ha un gestore ed2k:// registrato.' + #13#10 +
      'Apri eMule e registra prima i link ED2K, poi rilancia il setup.', mbCriticalError, MB_OK);
    Exit;
  end;

  Param := ExpandConstant('{param:DOMINI|}');
  if WizardSilent and (Param <> '') and (Lowercase(Param) <> 'tutti') then begin
    List := TStringList.Create;
    try
      Result := ParseDomains(Param, List, Bad) and (List.Count > 0);
    finally
      List.Free;
    end;
    if not Result then
      MsgBox('Dominio non valido in /DOMINI: ' + Bad, mbCriticalError, MB_OK);
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  Bad: String;
begin
  Result := True;
  if (CurPageID = DomainsPage.ID) and SelectedRadio.Checked then begin
    if not ParseDomains(DomainsMemo.Text, DomainList, Bad) then begin
      MsgBox('Dominio non valido: ' + Bad + #13#10#13#10 +
        'Scrivi un dominio per riga, per esempio sito.it. I domini con caratteri accentati vanno scritti in forma xn--.',
        mbError, MB_OK);
      Result := False;
    end else if DomainList.Count = 0 then begin
      MsgBox('Inserisci almeno un dominio oppure scegli "Tutti i domini".', mbError, MB_OK);
      Result := False;
    end;
  end;
end;

function UpdateReadyMemo(Space, NewLine, MemoUserInfoInfo, MemoDirInfo, MemoTypeInfo,
  MemoComponentsInfo, MemoGroupInfo, MemoTasksInfo: String): String;
var
  I: Integer;
begin
  Result := MemoDirInfo + NewLine + NewLine + 'Siti abilitati:' + NewLine;
  if AllRadio.Checked then
    Result := Result + Space + 'tutti i domini (HTTP e HTTPS)' + NewLine
  else
    for I := 0 to DomainList.Count - 1 do
      Result := Result + Space + DomainList[I] + ' e sottodomini' + NewLine;
end;

procedure RegisterPreviousData(PreviousDataKey: Integer);
var
  Saved: String;
begin
  if AllRadio.Checked then
    SetPreviousData(PreviousDataKey, 'DomainMode', 'all')
  else
    SetPreviousData(PreviousDataKey, 'DomainMode', 'selected');
  Saved := Trim(DomainsMemo.Text);
  StringChangeEx(Saved, #13#10, ',', True);
  SetPreviousData(PreviousDataKey, 'Domains', Saved);
end;

function MatchesBlock(): String;
var
  I: Integer;
begin
  if AllRadio.Checked then
    Result := #10 + '        "http://*/*",' + #10 + '        "https://*/*"'
  else begin
    Result := '';
    for I := 0 to DomainList.Count - 1 do begin
      if I > 0 then Result := Result + ',';
      Result := Result + #10 + '        "*://*.' + DomainList[I] + '/*"';
    end;
  end;
  Result := Result + #10 + '      ';
end;

// Sostituisce il contenuto di ogni lista "matches" del manifest; restituisce quante ne ha trovate.
function ReplaceMatches(var S: String; Items: String): Integer;
var
  Key, Rest, Res: String;
  P, Q: Integer;
begin
  Key := '"matches": [';
  Result := 0;
  Res := '';
  Rest := S;
  P := Pos(Key, Rest);
  while P > 0 do begin
    Res := Res + Copy(Rest, 1, P + Length(Key) - 1);
    Rest := Copy(Rest, P + Length(Key), Length(Rest));
    Q := Pos(']', Rest);
    if Q = 0 then Break;
    Res := Res + Items;
    Rest := Copy(Rest, Q, Length(Rest));
    Result := Result + 1;
    P := Pos(Key, Rest);
  end;
  S := Res + Rest;
end;

// JSON solo ASCII: i caratteri non ASCII del percorso (es. nome utente accentato) diventano \uXXXX.
function JsonEscape(S: String): String;
var
  I: Integer;
  C: Char;
begin
  Result := '';
  for I := 1 to Length(S) do begin
    C := S[I];
    if C = '\' then
      Result := Result + '\\'
    else if C = '"' then
      Result := Result + '\"'
    else if (Ord(C) < 32) or (Ord(C) > 126) then
      Result := Result + '\u' + Format('%.4x', [Ord(C)])
    else
      Result := Result + C;
  end;
end;

procedure CopyToClipboard(Text: String);
var
  Code: Integer;
begin
  StringChangeEx(Text, '''', '''''', True);
  Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
    '-NoProfile -NonInteractive -Command "Set-Clipboard -Value ''' + Text + '''"',
    '', SW_HIDE, ewWaitUntilTerminated, Code);
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ManifestPath, Text, Bad, Json: String;
  Raw: AnsiString;
begin
  if CurStep <> ssPostInstall then Exit;

  if SelectedRadio.Checked then
    if (not ParseDomains(DomainsMemo.Text, DomainList, Bad)) or (DomainList.Count = 0) then
      RaiseException('Elenco domini non valido: ' + Bad);

  // Il manifest contiene solo caratteri ASCII.
  ManifestPath := ExpandConstant('{app}\Chrome\manifest.json');
  if not LoadStringFromFile(ManifestPath, Raw) then
    RaiseException('Impossibile leggere ' + ManifestPath);
  Text := Raw;
  if ReplaceMatches(Text, MatchesBlock()) <> 2 then
    RaiseException('manifest.json inatteso: servono esattamente due liste "matches".');
  if not SaveStringToFile(ManifestPath, Text, False) then
    RaiseException('Impossibile scrivere ' + ManifestPath);

  Json := '{' + #13#10 +
    '  "name": "' + HostName + '",' + #13#10 +
    '  "description": "Dimomule Personal Native Messaging Host",' + #13#10 +
    '  "path": "' + JsonEscape(ExpandConstant('{app}\NativeHost\DimomuleNativeHost.exe')) + '",' + #13#10 +
    '  "type": "stdio",' + #13#10 +
    '  "allowed_origins": ["chrome-extension://' + ExtensionId + '/"]' + #13#10 +
    '}' + #13#10;
  if not SaveStringToFile(ExpandConstant('{app}\NativeHost\native-host.json'), Json, False) then
    RaiseException('Impossibile scrivere native-host.json');

  CopyToClipboard(ExpandConstant('{app}\Chrome'));
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID <> wpFinished then Exit;
  WizardForm.FinishedLabel.Caption :=
    'Installazione completata. Ultimo passo, da fare una sola volta in Google Chrome:' + #13#10#13#10 +
    '1. apri chrome://extensions' + #13#10 +
    '2. attiva "Modalità sviluppatore" (in alto a destra)' + #13#10 +
    '3. premi "Carica estensione non pacchettizzata"' + #13#10 +
    '4. seleziona la cartella:' + #13#10 +
    '    ' + ExpandConstant('{app}\Chrome') + #13#10 +
    '    (il percorso è già negli appunti: incollalo con Ctrl+V)' + #13#10#13#10 +
    'Per aggiornare o cambiare i siti abilitati basta rieseguire il setup e poi premere ' +
    '"Ricarica" sulla scheda Dimomule Personal in chrome://extensions.';
  WizardForm.AdjustLabelHeight(WizardForm.FinishedLabel);
  WizardForm.RunList.Top := WizardForm.FinishedLabel.Top + WizardForm.FinishedLabel.Height + ScaleY(12);
end;
