# dotfiles

Personal workstation setup, managed with [chezmoi](https://www.chezmoi.io/).
macOS for now; Linux and Windows later.

## Bootstrap a new machine (macOS)

```sh
xcode-select --install   # git + build tools; wait for it to finish
cd ~ && sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply davidsung
```

This installs chezmoi to `~/.local/bin`, clones this repo, and applies it:

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
2. **GitHub CLI**: `gh auth login` and choose **SSH**. When asked to generate or
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
- **Runtimes** (node, python, ...): `chezmoi edit ~/.config/mise/config.toml`, then
  `chezmoi apply`; `mise install` reruns automatically.
- **Changed a managed file outside chezmoi** (e.g. `gh config set`): `chezmoi re-add`
  copies it back into the repo.
