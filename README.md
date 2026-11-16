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
| `personal` | MacBook Pro | None |
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
