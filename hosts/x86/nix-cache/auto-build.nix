# Automatic nix build service for caching
{
  config,
  pkgs,
  host,
  ...
}:

{
  # --- Auto-Build Service ---
  systemd.services.nix-auto-build = {
    description = "Build and cache NixOS configurations";
    path = with pkgs; [
      git
      git-crypt
      nix
      openssh
      jq
      uv
      python3
      bash
      util-linux
    ];
    script = ''
      set -euo pipefail
      export NIX_REMOTE=daemon

      DOTFILES="/var/lib/nix-auto-build/dotfiles"

      if [ ! -d "$DOTFILES" ]; then
        runuser -u ryan -- git clone git@github.com:rwade628/dot.nix "$DOTFILES"
      else
        runuser -u ryan -- bash -c '
          cd "$1"
          git fetch origin
          git reset --hard origin/main
        ' _ "$DOTFILES"
      fi

      runuser -u ryan -- bash -c '
        cd "$1"
        nix flake update

        export XDG_CACHE_HOME="/var/lib/nix-auto-build/.cache"
        if [ -f "scripts/ai/update_overrides.py" ]; then
          echo "Running update_overrides.py..."
          uv run scripts/ai/update_overrides.py || echo "Warning: Update overrides failed"
        fi
      ' _ "$DOTFILES"

      cd "$DOTFILES"

      NIXPKGS_KEY=$(jq -r .nodes.root.inputs.nixpkgs flake.lock)
      COMMIT_ID=$(jq -r .nodes.$NIXPKGS_KEY.locked.rev flake.lock)

      BUILD_SUCCESS=true
      for target_host in loki; do
        echo "Building $target_host..."
        if nix build .#nixosConfigurations.$target_host.config.system.build.toplevel \
          --out-link "/var/lib/nix-auto-build/result-$target_host" \
          --print-out-paths \
          --cores 1 \
          --max-jobs 1; then
            echo "$COMMIT_ID" > "/var/lib/nix-auto-build/$target_host.rev"
        else
            BUILD_SUCCESS=false
            echo "Warning: $target_host build failed, continuing..."
        fi
      done

      if [ "$BUILD_SUCCESS" = true ]; then
        runuser -u ryan -- bash -c '
          cd "$1"
          if ! git diff --quiet || ! git diff --staged --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
            git add flake.lock
            git add -u  # Catches changes made by update_overrides.py
            git commit -m "chore: automated nightly flake updates"
            git push origin main
            echo "Successfully pushed updated lockfile."
          else
            echo "No updates available today."
          fi
        ' _ "$DOTFILES"
      else
        echo "Build failed, skipping git push to ensure client stability."
        exit 1
      fi

      echo "All builds completed at $(date)"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      # Generous timeout for long Vulkan / llama.cpp builds
      TimeoutStartSec = "3d";
    };
  };

  # --- Daily Timer ---
  systemd.timers.nix-auto-build = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 02:00:00";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  # Ensure build directory exists and is owned by ryan
  systemd.tmpfiles.rules = [
    "d /var/lib/nix-auto-build 0755 ryan users -"
  ];
}
