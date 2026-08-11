# Darwin hosts via nix-darwin, kept as a parallel platform tree

The flake previously only produced NixOS systems (`lib.nixosSystem`), and
`modules/nixos/core` carried an aspirational comment claiming NixOS/darwin compatibility that
was never actually true — it uses NixOS-only options (`services.printing`, `users.mutableUsers`,
`boot.*`) that don't exist under nix-darwin.

To add a Mac host (`idun`), we're adding `nix-darwin` as a new flake input producing a real
`darwinConfigurations` output via a new `mkDarwinHost` builder, with its own
`hosts/darwin/<hostname>/` tree as a sibling to `hosts/x86/` (not a rename/merge of the
existing NixOS host layout). System-level config lives in a new, standalone
`modules/darwin/core` written from scratch rather than extracted into a module shared with
`modules/nixos/core` — nix-darwin and NixOS share almost no system-level option surface
(users, services, boot), so forcing a shared abstraction before any darwin code existed risked
building the wrong one. Duplication (e.g. of timezone/locale) is accepted for now; extraction
happens later only if real drift shows up.

GUI apps that aren't well-packaged in nixpkgs for `aarch64-darwin` (proprietary/closed-source
macOS apps) are installed via nix-darwin's `homebrew` module (`homebrew.casks`), the standard
nix-darwin pattern. Everything that builds cleanly from nixpkgs stays pure nixpkgs.

nix-darwin does not create user accounts the way NixOS's `users.users.<name>.isNormalUser`
does — the Mac's user account must already exist (created via macOS Setup Assistant). The
darwin host config references it via `system.primaryUser` and `users.users.<name>` (for
shell/uid/ssh-authorized-keys overrides only), not account creation.
