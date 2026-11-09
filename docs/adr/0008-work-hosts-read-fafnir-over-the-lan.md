# Work hosts read Fafnir over the LAN, via a per-name resolver

Partially supersedes [ADR-0007](./0007-work-hosts.md), which kept the Attic cache (`fafnir`) off
Work hosts entirely. The first real switch on `brokkr` showed the cost was bigger than that ADR
assumed: without fafnir, every overlay modification and anything cache.nixos.org's slow local
POP serves becomes a long local build or download.

A Work host now substitutes from fafnir through the homelab's **LAN** address
(`attic.<domain>` on the cluster's `envoy-internal` gateway, which already served Attic over
HTTPS - no homelab change was needed). Personal hosts keep the tailnet address. Both come from a
new `hostSpec.fafnirEndpoint`: it defaults to the tailnet address, or to `null` for Work hosts,
and the Work wrapper flake supplies the LAN address, because the homelab domain is private and
this repo is public. CI's placeholder `brokkr` therefore still builds with no fafnir.

The work Mac uses its employer's DNS resolver, which can't see the homelab's internal names, even
though the machine can reach the home router directly. So `hostSpec.fafnirResolver` (also set
only by the wrapper) makes nix-darwin write a macOS per-name resolver,
`/etc/resolver/attic.<domain>`, that sends lookups for **that one name only** to the home router
(`10.0.10.1`) with a 1 s timeout. All other lookups still go to the employer's DNS. Away from
home the lookup fails quickly, and `connect-timeout = 5` already makes Nix fall back to
cache.nixos.org. This was tested by hand on `brokkr` before any code was written.

This is consistent with ADR-0007's reasoning rather than a reversal of it. That ADR rejected
*joining the tailnet* because it opens a path from an employer device into the homelab. Reading
fafnir over the LAN opens nothing new: fafnir is public-read (no token reaches the machine),
`brokkr` is already on `HOME_VLAN` when at home, and nothing joins any network. Accordingly the
Attic substituter is no longer part of **Homelab tooling** in `CONTEXT.md`. It's a package
source, not something used to reach or operate the homelab.

## Trust in the other direction

ADR-0007 protected the homelab from the work Mac. This change adds trust the other way: `brokkr`
now trusts `fafnir`'s signing key, so anything signed with it (the key lives in the cluster,
pushes come from this repo's CI) installs on an employer-owned machine as if genuine. That is
accepted because it adds little: `brokkr` already runs whatever this public flake says, which is
an equally direct channel into the machine, and CI is the cache's only writer.

## Considered options

- **Join the work Mac to the tailnet.** Already rejected by ADR-0007, for the reason above.
- **A read-only public Attic endpoint** (the fix ADR-0007 pointed to). Works away from home too,
  but it puts the cache on the internet. The LAN covers where large switches actually happen.
- **Hard-code `10.0.10.246` as the substituter URL.** Doesn't work: the TLS certificate is for the
  hostname, and `envoy-internal` routes by hostname, so a bare-IP request matches no route.
  Nix has no setting to override the hostname or SNI it sends.
- **An `/etc/hosts` entry.** Works at home, but always resolves to the home address. On
  other networks Nix would connect to whatever owns `10.0.10.246` and only fail at TLS, after the
  connect timeout. It also hard-codes the IP instead of asking home DNS.
- **A resolver for the whole homelab domain.** Wider than needed. Scoping it to `attic.<domain>`
  keeps the employer's DNS answering everything else.
- **A `modules` argument on `mkDarwinSystem`** so the wrapper could set `extra-substituters`
  itself. More general, but it opens a way for the wrapper to configure anything, bypassing
  `hostSpec`. Supplying private values through `hostSpec` is the pattern ADR-0007 already set up.
- **A dedicated load-balancer IP for Attic.** Only needed if the work Mac moves to a Restricted
  Zone VLAN, where a narrow pinhole to the shared `envoy-internal` IP would expose every internal
  route. Revisit if that happens.

## Consequences

- The wrapper flake gains two values (`fafnirEndpoint`, `fafnirResolver`) - see
  [`docs/work-host-setup.md`](../work-host-setup.md).
- If the homelab's LAN gateway, its IP, or the router's DNS changes, only the wrapper needs
  updating. The tailnet path for personal hosts is unaffected.
- If the work Mac ever moves off `HOME_VLAN`, this stops working until a pinhole (and probably
  the dedicated LB IP above) exists.
