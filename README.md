# TL40-Dots — Dotfiles mit GNU Stow

Dieses Repository enthält deine Dotfiles, organisiert als Stow-Pakete.

Aktueller Inhalt:

- `bash/.bashrc` — deine bash-Konfiguration
- `starship/.config/starship.toml` — Konfiguration für Starship prompt
- `install.sh` — Hilfsskript, das die Pakete ins Home-Verzeichnis stowt

Wie benutzen

1. Wechsle ins Repository:

   cd /home/oliver/Projects/TL40-Dots

2. Installiere (erstes Mal oder nach Änderungen):

   stow -v -t "$HOME" bash starship

3. Entfernen / Rückgängig:

   stow -D -t "$HOME" bash starship

Hinweise

- Die Ordner (`bash`, `starship`) sind Stow-Pakete. Sie spiegeln die Pfade, wie sie im Home-Verzeichnis erscheinen sollen.
- Passe die Dateien in `bash/` oder `starship/` nach Bedarf an. Nach Änderungen erneut `stow -R` oder `stow -v -t "$HOME" <paket>` ausführen.

Backup & Commit Hinweise

- Vor dem Stowen mache ich eine Sicherung vorhandener Dateien in `~/dotfiles_backup/<timestamp>/` (falls installiertes `install.sh` benutzt wird, es macht das nicht automatisch).
- Nachdem du die Dateien angepasst hast, committe Änderungen im Repo und führe `stow -R -t "$HOME" <paket>` aus, um die Symlinks zu aktualisieren.

Weitere kleine Paketvorschläge

- `git/` — Sammlung nützlicher Git-Dotfiles (z.B. `.gitconfig`) — Vorlage im Repo.
- `nvim/` — Neovim-Konfiguration (`.config/nvim`) — Beispiel im Repo.
