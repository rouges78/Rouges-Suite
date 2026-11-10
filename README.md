# Rouges Suite

The Rouges suite of Windows apps, installed and updated with **Rouges@Launcher**: you install only the launcher, and
choose there which apps to install. The launcher and the apps speak English and Italian (they follow Windows'
language, or the one chosen in the launcher).

## Install

In PowerShell:

```powershell
irm https://raw.githubusercontent.com/rouges78/Rouges-Suite/main/install.ps1 | iex
```

The command downloads `RougesSetup.exe` from the latest release, checks its SHA-256 and runs it: the launcher installs
itself in `%LOCALAPPDATA%\Rouges\Launcher`, adds a shortcut to the Start menu and the desktop, and opens.
You can also download `RougesSetup.exe` from the [releases](https://github.com/rouges78/Rouges-Suite/releases)
(the first time, Windows SmartScreen may say "unrecognized app").

The launcher updates itself; apps are installed, updated and uninstalled from their cards in the launcher, or from
*Settings → Apps → Installed apps*.

## The apps

| App | What it does |
|---|---|
| **Rouges@FTP** | FTP, FTPS and SFTP file transfer |
| **Rouges@Mail** | Lightweight email |
| **Rouges@Browser** | Light, tracker-free browsing |
| **Rouges@FutureNote** | Text editor and notes |
| **Rouges@PDFKing** | PDF reader and editor |
| **Rouges@DB++** | Lightweight database client |
| **Rouges@Pc2Pc** | Lightweight remote desktop |
| **Rouges@Kalc+** | Tape calculator |

## Security

The app catalog (`catalog.json`) is signed: the launcher accepts it only with a valid signature (`catalog.json.sig`)
and only if it is not older than the one it already has. Each package is installed only if its SHA-256 matches the one
in the catalog.

## Made with Slint

Rouges@Launcher, Rouges@FTP, Rouges@FutureNote, Rouges@PDFKing, Rouges@Pc2Pc and Rouges@Kalc+ are built with
[Slint](https://slint.dev), used under the Slint Royalty-free License.

[![Made with Slint](https://github.com/slint-ui/slint/raw/master/logo/MadeWithSlint-logo-whitebg.png)](https://slint.dev)
