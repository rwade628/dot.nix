# Work host setup (brokkr)

How to bring up — or rebuild from scratch — the work Mac. The *why* is in
[ADR-0007](./adr/0007-work-hosts.md); this is the *how*.

The one idea to keep in mind: **the work Mac never switches this repo directly.** It switches a
tiny private **Work wrapper flake** at `~/.config/nix-darwin/`, which pulls this repo in as an
input and supplies the values this public repo must not contain (macOS account name, work git
identity). If something's confusing, it's probably because you're looking at the wrong flake.

## First-time setup

1. **Homebrew.** Install it from <https://brew.sh> first — nix-darwin's `homebrew` module manages
   casks (Ghostty) but does not install Homebrew itself.

2. **Nix.** Install upstream Nix, multi-user:

   ```sh
   curl -L https://nixos.org/nix/install | sh -s -- --daemon
   ```

   Not the Determinate installer's default (Determinate Nix): it manages the daemon and
   `nix.conf` itself, which conflicts with `nix.enable = true` in `modules/darwin/core/default.nix`.
   If Determinate Nix is already on the machine, either reinstall, or set `nix.enable = false`
   for Work hosts in that module.

3. **Wrapper flake.** Create `~/.config/nix-darwin/flake.nix`:

   ```nix
   {
     inputs.dotnix.url = "github:rwade628/dot.nix";

     outputs =
       { dotnix, ... }:
       {
         darwinConfigurations.brokkr = dotnix.lib.mkDarwinSystem {
           hostName = "brokkr";
           hostSpec.user = {
             osName = "first.last"; # output of `whoami`
             gitIdentity = {
               name = "First Last";
               email = "first.last@company.com";
             };
           };
         };
       };
   }
   ```

   Don't push it anywhere. Optionally `git init` it locally for history — but then remember the
   flake only sees **git-tracked** files, so `git add` before switching.

4. **Move aside files nix-darwin refuses to overwrite.** On a fresh Mac the first activation
   stops on existing `/etc/zshrc`, `/etc/zprofile`, `/etc/bashrc` (it names them). Rename each to
   `<file>.before-nix-darwin` and rerun.

5. **First switch** (needs sudo — nix-darwin activates as root):

   ```sh
   sudo nix --extra-experimental-features 'nix-command flakes' \
     run nix-darwin/master#darwin-rebuild -- switch --flake ~/.config/nix-darwin#brokkr
   ```

6. **Git auth.** The first `git push`/`clone` of a private work repo opens a browser for Git
   Credential Manager; sign in with the EMU account. GCM stores it in the macOS Keychain.

7. Open a new Ghostty window — zsh, tmux, Neovim and theming should match idun.

## Day to day

Update after pushing changes to dot.nix from a personal machine:

```sh
nix flake update dotnix --flake ~/.config/nix-darwin
nh darwin switch -H brokkr        # NH_DARWIN_FLAKE already points at the wrapper
```

Always name the output (`-H brokkr` / `#brokkr`): the machine's real hostname belongs to IT and
isn't `brokkr`, so auto-detection picks the wrong output (or none).

To try an uncommitted dot.nix change before pushing it, from a checkout on the work Mac:

```sh
nh darwin switch -H brokkr -- --override-input dotnix path:$HOME/git/dot.nix
```

Commit and push dot.nix changes from a personal machine — the EMU account can't push to personal
repos.

## Troubleshooting

- **`error: flake ... does not provide attribute darwinConfigurations.<some-name>`** — you didn't
  pass `-H brokkr` / `#brokkr`.
- **`programs.git.settings.user` empty / commits have no author** — the wrapper's `gitIdentity` is
  missing, or you built dot.nix's own `brokkr` (placeholders) instead of the wrapper.
- **Home directory is `/Users/ryan`** — same cause: `osName` wasn't supplied, so it fell back to
  the placeholder `ryan`.
- **A wrapper edit has no effect** — the wrapper is a git repo and the change isn't `git add`ed.
- **Ghostty missing** — `brew` isn't installed or isn't on PATH; install it and switch again.
- **Daemon / `nix.conf` errors on activation** — Determinate Nix is installed; see step 2.
- **Slow switch, lots of local builds** — expected for this repo's overlay modifications: Work
  hosts don't use the Attic cache (ADR-0007). Stock packages still come from cache.nixos.org.
