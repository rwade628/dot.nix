# Work host setup (brokkr)

How to bring up — or rebuild from scratch — the work Mac. The *why* is in
[ADR-0007](./adr/0007-work-hosts.md); this is the *how*.

The one idea to keep in mind: **the work Mac never switches this repo directly.** It switches a
small private **Work wrapper flake** at `~/.config/nix-darwin/`, which pulls this repo in as an
input and adds everything employer-specific that this public repo must not contain: the private
values (macOS account name, work git identity), Work-only configuration (the employer's TLS trust
settings, work aliases and env), and the Work host's own sops secrets. If something's confusing,
it's probably because you're looking at the wrong flake.

Nothing employer-specific ever goes in this repo — not hostnames, CA bundle paths, internal tool
names, account names or emails. Everything below that names one is a placeholder you fill in
inside the wrapper.

## First-time setup

Throughout, `$CA` is the employer's CA bundle at the fixed path IT/MDM deploys it to. The
employer re-signs HTTPS traffic (to cache.nixos.org, channels.nixos.org, github.com, …), so
nothing Nix-related works until it trusts that bundle:

```sh
export CA=/path/to/employer-ca-bundle.pem   # wherever IT deploys it
curl --cacert "$CA" -sSfI https://cache.nixos.org >/dev/null && echo ok
```

Use the bundle **at its runtime path** everywhere (never copy it into the store or into
`security.pki.certificateFiles`), so IT's rotations are picked up without a rebuild.

1. **Homebrew.** Install it from <https://brew.sh> first — nix-darwin's `homebrew` module manages
   casks (Ghostty) but does not install Homebrew itself.

2. **Nix, via the Lix installer, pointed at the CA.** Same as idun: the
   [Lix installer](https://lix.systems/install/#on-any-other-linuxmacos-system) is used for
   bootstrap only; nix-darwin then runs its default Nix (nothing sets `nix.package`).

   ```sh
   curl --cacert "$CA" -sSf -L https://install.lix.systems/lix \
     | NIX_INSTALLER_SSL_CERT_FILE="$CA" sh -s -- install macos --ssl-cert-file "$CA"
   ```

   `--ssl-cert-file` (env `NIX_INSTALLER_SSL_CERT_FILE`) makes the installer use the bundle for
   its downloads **and** writes `ssl-cert-file` into `/etc/nix/nix.conf`, so the first switch can
   fetch. Once nix-darwin owns `nix.conf` that line is regenerated from the wrapper's
   `nix.settings`, which is why `work.nix` below must keep setting it.

   Not the Determinate installer: it manages the daemon and `nix.conf` itself, which conflicts with
   `nix.enable = true` in `modules/darwin/core/default.nix`.

3. **Age key** (decrypts the Work host's own secrets — see step 5). Generate it on the Mac:

   ```sh
   mkdir -p ~/.config/sops/age
   nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#age \
     -c age-keygen -o ~/.config/sops/age/keys.txt
   chmod 600 ~/.config/sops/age/keys.txt
   ```

   It never leaves the machine and is **not backed up**: every secret it protects is a work token
   that can be reissued. Lose the key → generate a new one and re-enter the secrets. There's no SSH
   host key to derive one from (sshd is off on Work hosts), and the Mac is never a recipient in this
   repo's `.sops.yaml` or of the Common secrets file.

4. **Wrapper flake.** Create `~/.config/nix-darwin/` with these files and `git init` it (the flake
   only sees **git-tracked** files, so `git add` before every switch). Don't push it anywhere.

   `flake.nix` — layers the wrapper's modules over this repo's config with `extendModules`, so
   `mkDarwinSystem`'s signature never has to grow:

   ```nix
   {
     inputs.dotnix.url = "github:rwade628/dot.nix";

     outputs =
       { dotnix, ... }:
       {
         darwinConfigurations.brokkr =
           (dotnix.lib.mkDarwinSystem {
             hostName = "brokkr";
             hostSpec.user = {
               osName = "first.last"; # output of `whoami`
               gitIdentity = {
                 name = "First Last";
                 email = "first.last@company.com";
               };
             };
           }).extendModules
             {
               modules = [
                 ./work.nix
                 {
                   home-manager.sharedModules = [
                     dotnix.inputs.sops-nix.homeManagerModules.sops
                     ./work-home.nix
                   ];
                 }
               ];
             };
       };
   }
   ```

   `work.nix` — system-level Work config, starting with the CA:

   ```nix
   let
     ca = "/path/to/employer-ca-bundle.pem";
   in
   {
     # Keeps the daemon trusting the bundle once nix-darwin owns nix.conf.
     nix.settings.ssl-cert-file = ca;
     # Shells and tools. nix-darwin also passes NIX_SSL_CERT_FILE into the
     # nix-daemon launchd job, so set it here rather than only in zsh.
     environment.variables = {
       NIX_SSL_CERT_FILE = ca;
       SSL_CERT_FILE = ca;
       REQUESTS_CA_BUNDLE = ca;
       NODE_EXTRA_CA_CERTS = ca;
     };
   }
   ```

   `work-home.nix` — user-level Work config: aliases, env and secrets (`config` here is the
   home-manager config):

   ```nix
   { config, ... }:
   {
     sops = {
       age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
       defaultSopsFile = ./secrets.yaml;
       secrets.some_work_token = { };
     };
     # sops on macOS otherwise looks in ~/Library/Application Support/sops/age/.
     home.sessionVariables.SOPS_AGE_KEY_FILE = config.sops.age.keyFile;

     programs.zsh.initContent = ''
       export SOME_WORK_TOKEN="$(cat ${config.sops.secrets.some_work_token.path})"
     '';

     home.shellAliases = {
       # work-only aliases
     };
   }
   ```

   Secrets are **never** plain strings in a `.nix` file: anything evaluated lands in the
   world-readable `/nix/store`. Only the secret's *path* is interpolated above; the value is
   decrypted at activation into `~/.config/sops-nix/secrets/` and read at shell start.

5. **Work secrets.** In the wrapper, create `.sops.yaml` naming the age key from step 3, then the
   encrypted file:

   ```sh
   cd ~/.config/nix-darwin
   cat > .sops.yaml <<EOF
   creation_rules:
     - path_regex: secrets\.yaml$
       age: $(grep -o 'age1.*' ~/.config/sops/age/keys.txt)
   EOF
   export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt   # not sops's macOS default, see below
   nix shell nixpkgs#sops -c sops secrets.yaml   # opens $EDITOR; add some_work_token: ...
   git add -A
   ```

   On macOS `sops` looks for the key in `~/Library/Application Support/sops/age/keys.txt`, not
   `~/.config`, hence `SOPS_AGE_KEY_FILE` for this first edit. After the first switch,
   `work-home.nix` sets it in every shell, so later edits are just
   `nix shell nixpkgs#sops -c sops secrets.yaml`.

6. **Move aside pre-existing dotfiles.** home-manager won't overwrite them, and several conflict
   silently rather than failing: zsh reads from `~/.config/zsh` so a leftover `~/.zshrc` is just
   ignored, and a `~/.gitconfig` *overrides* home-manager's `~/.config/git/config`. Rename each one
   that exists to `<file>.before-nix-darwin` (the suffix nix-darwin's own error message asks
   for). The `/etc` ones are files the Lix installer wrote or macOS ships, which nix-darwin refuses
   to replace — `/etc/nix/nix.conf` included, which is why the first switch passes the CA on the
   command line. Run the next step from this same shell: with Lix's `/etc/zshenv` aside, a new
   shell won't have `nix` on PATH until the switch completes.

   ```sh
   for f in ~/.zshrc ~/.zprofile ~/.gitconfig ~/.tmux.conf ~/.config/nvim; do
     [ -e "$f" ] || [ -L "$f" ] && mv "$f" "$f.before-nix-darwin"
   done
   for f in /etc/zshrc /etc/zprofile /etc/zshenv /etc/bashrc /etc/nix/nix.conf; do
     [ -e "$f" ] && sudo mv "$f" "$f.before-nix-darwin"
   done
   ```

   Anything work-relevant in the old files (aliases, env) moves into `work-home.nix`, not this
   repo. Homebrew formulae stay installed (Homebrew cleanup is `"none"` on Work hosts); Nix's
   copies come first on PATH, and you can prune the brew ones later by hand.

7. **First switch** (needs sudo — nix-darwin activates as root):

   ```sh
   cd ~/.config/nix-darwin && git add -A
   sudo NIX_SSL_CERT_FILE="$CA" nix --extra-experimental-features 'nix-command flakes' \
     --option ssl-cert-file "$CA" \
     --option extra-substituters https://catppuccin.cachix.org \
     --option extra-trusted-public-keys 'catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU=' \
     run nix-darwin/master#darwin-rebuild -- switch --flake ~/.config/nix-darwin#brokkr
   ```

   The `--option`s stand in for settings that only exist once nix-darwin has written `nix.conf`
   (`/etc/nix/nix.conf` was just moved aside): the CA from `work.nix`, and the catppuccin cache
   `modules/darwin/core/default.nix` adds for Work hosts (they have no Attic, so without it
   catppuccin's derivations build locally and fail behind the TLS interception). Later switches
   don't need them.

8. **Git auth.** The first `git push`/`clone` of a private work repo opens a browser for Git
   Credential Manager; sign in with the EMU account. GCM stores it in the macOS Keychain, keyed
   per repo path (`credential.useHttpPath`), so the EMU login and the personal dot.nix token
   (below) don't overwrite each other.

9. Open a new Ghostty window — zsh, tmux, Neovim and theming should match idun. Check
   `echo $NIX_SSL_CERT_FILE` and that a work secret is exported.

## Day to day

Update after pushing changes to dot.nix:

```sh
nix flake update dotnix --flake ~/.config/nix-darwin
nh darwin switch -H brokkr        # NH_DARWIN_FLAKE already points at the wrapper
```

Always name the output (`-H brokkr` / `#brokkr`): the machine's real hostname belongs to IT and
isn't `brokkr`, so auto-detection picks the wrong output (or none).

After editing a wrapper file, `git add` it before switching.

To try an uncommitted dot.nix change before pushing it, from a checkout on the work Mac (it lives
at `~/dot.nix` there, not `~/dot.nix` as on personal hosts — nothing depends on the location):

```sh
nh darwin switch -H brokkr -- --override-input dotnix path:$HOME/dot.nix
```

### Pushing dot.nix from the work Mac

The EMU account can't push to personal repos, so pushing uses a separate token:

1. On GitHub (personal account) create a **fine-grained** personal access token: repository access
   `rwade628/dot.nix` only, permission **Contents: read and write**, expiry ~7 days. Renew it when
   it lapses rather than making it long-lived.
2. Use an HTTPS remote: `git -C ~/dot.nix remote set-url origin https://github.com/rwade628/dot.nix.git`.
3. On the first push, GCM prompts; choose token auth and paste the PAT. It's stored for that repo
   path only.

Commits in any `github.com/rwade628/*` checkout automatically use the personal GitHub noreply
identity instead of the work one (an `includeIf` in `modules/home/core/git.nix`), so the work
email never reaches public history. Check with `git -C ~/dot.nix config user.email` before
the first commit.

**What may be pushed from the Work host:** only dot.nix, and nothing copied from work files —
no work config, hostnames, paths, snippets or notes, even "generic" ones. The Mac runs DLP that
inspects GitHub traffic; work-specific content belongs in the wrapper flake, which is never
pushed.

## Uninstall / rollback

1. Remove nix-darwin first, while Nix still works:

   ```sh
   sudo darwin-uninstaller
   ```

   It also moves every `/etc/*.before-nix-darwin` back into place (`/etc/zshrc`, `/etc/zshenv`,
   `/etc/nix/nix.conf`, …), which returns them to the Lix installer's state — what its
   uninstaller expects to undo next.

2. Uninstall Lix with the installer copy it left behind (`/nix/receipt.json` sits next to it):

   ```sh
   sudo /nix/nix-installer uninstall
   ```

3. Restore the home dotfiles (nothing restores these automatically):

   ```sh
   for f in ~/.zshrc ~/.zprofile ~/.gitconfig ~/.tmux.conf ~/.config/nvim; do
     [ -e "$f.before-nix-darwin" ] || [ -L "$f.before-nix-darwin" ] && mv "$f.before-nix-darwin" "$f"
   done
   ls /etc/*.before-nix-darwin /etc/nix/*.before-nix-darwin 2>/dev/null   # should be empty
   ```

4. Optionally delete `~/.config/nix-darwin`, `~/.config/sops/age/keys.txt` and
   `~/.config/sops-nix`, and revoke the dot.nix PAT on GitHub. Homebrew and its formulae were never
   touched, so nothing to restore there.

To roll back a bad switch without uninstalling: `sudo darwin-rebuild --rollback`, or switch the
wrapper at its previous `flake.lock` (`git -C ~/.config/nix-darwin checkout HEAD~ flake.lock`).

## Troubleshooting

- **`SSL connect error` / `unable to get local issuer certificate` / `SSL peer certificate or SSH
  remote key was not OK`** — something isn't using the employer CA. Check, in order:
  `$CA` still exists at that path (IT may have moved it); `nix config show ssl-cert-file`;
  `echo $NIX_SSL_CERT_FILE` in a new shell; and the daemon's env with
  `sudo launchctl print system/org.nixos.nix-daemon | grep SSL`. If `nix.conf` lost the setting
  (e.g. `work.nix` isn't `git add`ed), switch once with
  `sudo NIX_SSL_CERT_FILE="$CA" darwin-rebuild switch --option ssl-cert-file "$CA" --flake ~/.config/nix-darwin#brokkr`.
- **After a macOS update, the shell lost Nix** (no `nix`, wrong PATH, plain prompt) — the update
  replaced `/etc/zshrc` (and maybe `/etc/zprofile`/`/etc/zshenv`/`/etc/bashrc`). Move the new ones
  aside to `*.before-nix-darwin` again and rerun the switch from a shell that has Nix:
  `/run/current-system/sw/bin/darwin-rebuild switch --flake ~/.config/nix-darwin#brokkr` (with
  `sudo`).
- **`error: flake ... does not provide attribute darwinConfigurations.<some-name>`** — you didn't
  pass `-H brokkr` / `#brokkr`.
- **`programs.git.settings.user` empty / commits have no author** — the wrapper's `gitIdentity` is
  missing, or you built dot.nix's own `brokkr` (placeholders) instead of the wrapper.
- **dot.nix commits carry the work email** — the checkout's remote isn't
  `https://github.com/rwade628/...` (the noreply `includeIf` keys on it); check `git remote -v`.
- **Home directory is `/Users/ryan`** — same cause: `osName` wasn't supplied, so it fell back to
  the placeholder `ryan`.
- **A wrapper edit has no effect** — the change isn't `git add`ed.
- **A sops secret is missing / empty** — the key isn't at `~/.config/sops/age/keys.txt`, or
  `secrets.yaml` isn't `git add`ed; the sops-nix launchd agent logs why
  (`launchctl print gui/$UID/org.nix-community.home.sops-nix`).
- **Old shell config or a stray `~/.gitconfig` still taking effect** — a pre-existing dotfile
  wasn't moved aside (step 6).
- **Ghostty missing** — `brew` isn't installed or isn't on PATH; install it and switch again.
- **Daemon / `nix.conf` errors on activation** — Determinate Nix is installed; see step 2.
- **Slow switch, lots of local builds** — expected for this repo's overlay modifications: Work
  hosts don't use the Attic cache (ADR-0007). Stock packages still come from cache.nixos.org.
