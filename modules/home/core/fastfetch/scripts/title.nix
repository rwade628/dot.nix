{
  pkgs,
  ...
}:
pkgs.writeScript "title" ''
  #!/usr/bin/env zsh

  # Customize these color commands as you like
  local colorUser="$(tput setaf 6; tput bold)"
  local colorHost="$(tput setaf 4; tput bold)"
  local colorOS="$(tput setaf 5; tput bold)"
  local colorVersion="$(tput setaf 5; tput bold)"
  local colorCodename="$(tput setaf 5; tput bold; tput smul)"
  local colorBang="$(tput setaf 7; tput bold)"
  local colorReset="$(tput sgr0)"

  # Get uppercase user, host, OS name
  local u=$(whoami)
  local user (printf '%s%s' (string upper (string sub -l 1 $u)) (string lower (string sub -s 2 $u)))

  local h=$(hostname)
  local host (printf '%s%s' (string upper (string sub -l 1 $h)) (string lower (string sub -s 2 $h)))

  local osN=$(grep '^NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
  local osName (printf '%s%s' (string upper (string sub -l 1 $osN)) (string lower (string sub -s 2 $osN)))

  local osVersion=$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

  local osCN=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
  local osCodeName (printf '%s%s' (string upper (string sub -l 1 $osCN)) (string lower (string sub -s 2 $osCN)))

  # Print each part as you like
  echo -n "$colorUser$user$colorReset"
  echo -n "$colorBang"⸘ "
  echo -n "$colorHost$host$colorReset"
  echo -n "$colorBang"‽ "
  echo -n "$colorOS$osName" "$colorVersion$osVersion$colorReset" " "
  echo "$colorOS'('$colorCodename$osCodeName$colorReset$colorOS')'"
''
