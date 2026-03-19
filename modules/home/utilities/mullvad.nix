{ lib, ... }:
{
  home.activation.setupMullvadProfile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p $HOME/.mullvad/mullvadbrowser
        
        # Remove any existing read-only symlink from your previous home.file attempts
        rm -f $HOME/.mullvad/mullvadbrowser/profiles.ini
        
        # Create the file as a standard, writable file
        cat > $HOME/.mullvad/mullvadbrowser/profiles.ini <<EOF
    [Profile0]
    Name=default
    IsRelative=1
    Path=nixos-default
    Default=1

    [General]
    StartWithLastProfile=1
    Version=2
    EOF
  '';

  # Create the directory so Mullvad doesn't panic on first launch
  home.file.".mullvad/mullvadbrowser/nixos-default/.keep".text = "";
}
