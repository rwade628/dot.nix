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
      nix
      openssh
      jq
      uv
      python3
    ];
    script = ''
        set -euo pipefail
        export NIX_REMOTE=daemon

        DOTFILES="/var/lib/nix-auto-build/dotfiles"

        # It's okay this is owned by root
        git config --global --add safe.directory $DOTFILES

        # Clone or update dotfiles via SSH
        if [ ! -d "$DOTFILES" ]; then
          git clone git@github.com:rwade628/dot.nix "$DOTFILES"
        else
          cd "$DOTFILES"
          git fetch origin
          git reset --hard origin/main
        fi

        cd "$DOTFILES"

        # Update flake inputs
        nix flake update

        # Update overrides (e.g. llama-cpp)
        # We assume the script is robust and uses 'uv' for dependencies
        export XDG_CACHE_HOME="/var/lib/nix-auto-build/.cache"
        if [ -f "scripts/ai/update_overrides.py" ]; then
          echo "Running update_overrides.py..."
          uv run scripts/ai/update_overrides.py || echo "Warning: Update overrides failed"
        fi

        # Capture the nixpkgs revision from the updated flake.lock (used for builds)
        NIXPKGS_KEY=$(jq -r .nodes.root.inputs.nixpkgs flake.lock)
        COMMIT_ID=$(jq -r .nodes.$NIXPKGS_KEY.locked.rev flake.lock)

        # Build all host configurations (--cores 1 to limit memory usage)
        BUILD_SUCCESS=true
        for host in nixos loki; do
          echo "Building $host..."
          if nix build .#nixosConfigurations.$host.config.system.build.toplevel \
            --out-link "/var/lib/nix-auto-build/result-$host" \
            --print-out-paths \
            --cores 1 \
            --max-jobs 1; then
              echo "$COMMIT_ID" > "/var/lib/nix-auto-build/$host.rev"
          else
              BUILD_SUCCESS=false
              echo "Warning: $host build failed, continuing..."
          fi
        done

        # 4. PUSH CHANGES if build succeeded
      if [ "$BUILD_SUCCESS" = true ]; then
        git config user.name "Nix Auto Builder"
        git config user.email "builder@localhost"
        
        # Commit if there are changes
        if ! git diff --quiet || ! git diff --staged --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
          git add flake.lock
          git add -u  # Catches changes made by update_overrides.py
          git commit -m "chore: automated nightly flake updates"
          git push origin main
          echo "Successfully pushed updated lockfile."
        else
          echo "No updates available today."
        fi
      else
        echo "Build failed, skipping git push to ensure client stability."
        exit 1
      fi

        echo "All builds completed at $(date)"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "ryan";
      # Generous timeout for CUDA builds
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

  # Ensure build directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/nix-auto-build 0755 root root -"
  ];
}
