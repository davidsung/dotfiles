# dotfiles

Personal workstation setup, managed with [chezmoi](https://www.chezmoi.io/).
macOS for now; Linux and Windows later.

## Bootstrap a new machine (macOS)

```sh
xcode-select --install   # git + build tools; wait for it to finish
cd ~ && sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply davidsung
```

chezmoi asks one question, **Machine profile**, then remembers the answer on that machine:

| Profile | Machine | Extras on top of the common packages |
|---|---|---|
| `personal` | MacBook Pro | Adobe Creative Cloud |
| `home` | Mac mini (detected as the default) | Tailscale (Standalone app), openhue |
| `work` | Work Mac laptop | None. Also asks for your work git email |
| `game` | Windows | Chosen automatically (Windows support coming) |
| `lab` | Linux | Chosen automatically (Linux support coming) |

Change it later with `chezmoi init --prompt`; check it with `chezmoi data | jq .profile`.
Switching profiles doesn't uninstall packages; remove those yourself.

It then installs chezmoi to `~/.local/bin`, clones this repo, and applies it:

1. **Hook**: installs Homebrew (asks for your password) and the 1Password app + CLI
2. **Packages**: `brew bundle` from `.chezmoidata/packages.yaml`
3. **Dotfiles**: `.zshenv`, `.zprofile`, `.zshrc`, `.gitconfig`, `.ssh/config`,
   `.config/gh/config.yml`, `.config/mise/config.toml`
4. **Runtimes**: `mise install` (Node 24, from `~/.config/mise/config.toml`)
5. **Claude Code**: native installer (self-updating)

Open a new terminal afterwards so `~/.zprofile` puts Homebrew and `~/.local/bin` on PATH.

### After bootstrap

1. **1Password**: sign in, then enable *Settings → Developer → Use the SSH agent*.
   `~/.ssh/config` points GitHub at it, and `git push` to GitHub goes over SSH.
2. **Tailscale** (`home`): open the Tailscale app, allow its system extension in
   System Settings when asked, then sign in.
3. **GitHub CLI**: `gh auth login` and choose **SSH**. When asked to generate or
   upload an SSH key, say **No**: the key lives in 1Password and is already on
   GitHub. Then check with `ssh -T git@github.com` (approve the 1Password prompt).

### Existing machine: when chezmoi asks a new question

If the repo adds a new setup question (like **Machine profile**), a plain
`chezmoi update` fails with `map has no entry for key "..."`. Pull, answer, then apply:

```sh
chezmoi update --apply=false   # pull only
chezmoi init                   # answer the new question(s)
chezmoi apply
```

## Adobe Creative Cloud (`personal`)

Homebrew installs only the **Creative Cloud app** (`adobe-creative-cloud`). The first
install asks for your Mac password in the terminal, so run `chezmoi apply` in a real
terminal window. Then:

1. Open Creative Cloud and sign in. A personal plan allows signing in on **2 computers at a time**.
2. Install Photoshop, Lightroom, Acrobat, etc. from inside Creative Cloud (not from Homebrew).
3. Turn on auto-update in Creative Cloud's preferences. Creative Cloud updates itself;
   `brew bundle` leaves it alone.

### Removing Creative Cloud

Order matters: the apps need Creative Cloud to uninstall them.

1. **Uninstall each app** in Creative Cloud: *Apps → Installed → ⋯ → Uninstall* (Acrobat too).
2. **Sign out** (*Account → Sign out*) to free one of your 2 sign-ins.
3. **Stop chezmoi reinstalling it**: remove `adobe-creative-cloud` from
   `profiles.personal.casks` in `.chezmoidata/packages.yaml`, commit and push.
4. **Remove the Creative Cloud app** (asks for your password; stops Adobe's background services):
   ```sh
   brew uninstall --cask --zap adobe-creative-cloud   # --zap also removes preferences and caches
   ```
5. **Clean up leftovers**, if any Adobe folders or menu-bar items remain:
   ```sh
   brew install --cask adobe-creative-cloud-cleaner-tool
   open -a "Adobe Creative Cloud Cleaner Tool"             # choose "Clean All"
   brew uninstall --cask adobe-creative-cloud-cleaner-tool
   ```

## Day to day

```sh
chezmoi edit ~/.zshrc   # edit the source copy
chezmoi diff            # preview
chezmoi apply           # apply
chezmoi update          # pull from GitHub and apply
chezmoi upgrade         # update chezmoi itself (not managed by Homebrew)
```

- **Homebrew packages**: add to `.chezmoidata/packages.yaml` (grouped by category,
  one-line reason each), then `chezmoi apply`; `brew bundle` reruns automatically.
  Profile-only packages go under `profiles.<profile>`. Formulae from third-party taps
  (`tap/name`) are trusted individually by the install script.
- **Runtimes** (node, python, ...): `chezmoi edit ~/.config/mise/config.toml`, then
  `chezmoi apply`; `mise install` reruns automatically.
- **Changed a managed file outside chezmoi** (e.g. `gh config set`): `chezmoi re-add`
  copies it back into the repo.
