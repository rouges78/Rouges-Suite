# Rouges Suite

Le app della suite Rouges per Windows, da installare e aggiornare con **Rouges@Launcher**: si installa solo il
launcher, e da lì si sceglie quali app installare.

## Installare

In PowerShell:

```powershell
irm https://raw.githubusercontent.com/rouges78/Rouges-Suite/main/install.ps1 | iex
```

Il comando scarica `RougesSetup.exe` dall'ultima Release, ne controlla l'impronta SHA-256 e lo avvia: il launcher si
installa in `%LOCALAPPDATA%\Rouges\Launcher`, con il collegamento nel menu Start e sul desktop, e si apre.
In alternativa si può scaricare `RougesSetup.exe` dalle [Release](https://github.com/rouges78/Rouges-Suite/releases)
(la prima volta Windows SmartScreen può mostrare "app non riconosciuta").

Il launcher si aggiorna da solo; le app si installano, si aggiornano e si disinstallano dalle loro schede, oppure da
*Impostazioni → App installate*.

## Le app

| App | Cosa fa |
|---|---|
| **Rouges@FTP** | Trasferimento file FTP, FTPS e SFTP |
| **Rouges@Mail** | Posta elettronica leggera |
| **Rouges@Browser** | Navigazione leggera e senza tracker |
| **Rouges@FutureNote** | Editor di testo e appunti |
| **Rouges@PDFKing** | Lettore ed editor PDF |
| **Rouges@DB++** | Client database leggero |
| **Rouges@Pc2Pc** | Desktop remoto leggero |
| **Rouges@Kalc+** | Calcolatrice a nastro |

## Sicurezza

Il catalogo delle app (`catalog.json`) è firmato: il launcher lo accetta solo con una firma valida
(`catalog.json.sig`) e solo se non è più vecchio di quello già ricevuto. Ogni pacchetto viene installato solo se la
sua impronta SHA-256 corrisponde a quella del catalogo.

## Made with Slint

Rouges@Launcher, Rouges@FTP, Rouges@FutureNote, Rouges@PDFKing, Rouges@Pc2Pc e Rouges@Kalc+ sono fatte con
[Slint](https://slint.dev), usato con la licenza Slint Royalty-free.

[![Made with Slint](https://github.com/slint-ui/slint/raw/master/logo/MadeWithSlint-logo-whitebg.png)](https://slint.dev)
