# secrets: keep API keys in 1Password, cache them in this Mac's Keychain, and export
# selected ones at login. Which keys exist is listed in the private repo:
#   ~/.config/dotfiles-private/secrets.conf   (name  export-as|-  op://vault/item/field)
#
#   secrets sync [name...]  copy keys from 1Password into Keychain (needs the op CLI)
#   secrets list            show which keys this Mac has (never the values)
#   secrets get <name>      print one value, e.g.  FOO_API_KEY=$(secrets get foo) tool
#   secrets rm <name>       remove a key from this Mac's Keychain
#   secrets export          export keys marked for export (run by ~/.zprofile)

: ${SECRETS_CONF:=$HOME/.config/dotfiles-private/secrets.conf}
typeset -g _SECRETS_SERVICE_PREFIX="dotfiles."

# Print "name export ref" for each entry in secrets.conf, skipping comments/blank lines.
_secrets_entries() {
  [[ -r $SECRETS_CONF ]] || return 0
  local line
  while IFS= read -r line; do
    [[ $line =~ '^[[:space:]]*(#|$)' ]] && continue   # skip comments and blank lines
    print -r -- "$line"
  done < "$SECRETS_CONF"
}

_secrets_keychain_get() {
  security find-generic-password -a "$USER" -s "${_SECRETS_SERVICE_PREFIX}$1" -w 2>/dev/null
}

# Write via `security -i` on stdin so the value never appears in the process list.
_secrets_keychain_set() {
  printf 'add-generic-password -U -a "%s" -s "%s" -w "%s"\n' \
    "$USER" "${_SECRETS_SERVICE_PREFIX}$1" "$2" | security -i >/dev/null
}

secrets() {
  local cmd=${1:-help}; (( $# )) && shift
  local name var ref value found
  case $cmd in
    sync)
      command -v op >/dev/null || { print -u2 "secrets: 1Password CLI (op) not found"; return 1; }
      [[ -r $SECRETS_CONF ]] || { print -u2 "secrets: no list at $SECRETS_CONF"; return 1; }
      local -i ok=0 failed=0
      while read -r name var ref; do
        (( $# )) && [[ ${@[(Ie)$name]} -eq 0 ]] && continue
        if value="$(op read "$ref" 2>/dev/null)" && [[ -n $value ]]; then
          _secrets_keychain_set "$name" "$value"
          [[ $var != "-" ]] && export "$var=$value"
          print "  ✓ $name"; (( ok++ ))
        else
          print -u2 "  ✗ $name  (could not read $ref)"; (( failed++ ))
        fi
      done < <(_secrets_entries)
      unset value
      print "Synced $ok key(s)$( (( failed )) && print ", $failed failed"). Exported keys are set in this shell; open new terminals to pick them up elsewhere."
      (( failed == 0 ))
      ;;
    list)
      [[ -r $SECRETS_CONF ]] || { print "No list at $SECRETS_CONF (private repo not cloned yet?)"; return 0; }
      printf '%-12s %-28s %s\n' NAME EXPORT KEYCHAIN
      while read -r name var ref; do
        _secrets_keychain_get "$name" >/dev/null && found=present || found=missing
        printf '%-12s %-28s %s\n' "$name" "$var" "$found"
      done < <(_secrets_entries)
      ;;
    get)
      [[ -n $1 ]] || { print -u2 "usage: secrets get <name>"; return 2; }
      _secrets_keychain_get "$1" || { print -u2 "secrets: '$1' not in Keychain (run: secrets sync $1)"; return 1; }
      ;;
    rm)
      [[ -n $1 ]] || { print -u2 "usage: secrets rm <name>"; return 2; }
      security delete-generic-password -a "$USER" -s "${_SECRETS_SERVICE_PREFIX}$1" >/dev/null 2>&1 \
        && print "Removed $1 from Keychain" || { print -u2 "secrets: '$1' not in Keychain"; return 1; }
      ;;
    export)
      while read -r name var ref; do
        [[ $var == "-" ]] && continue
        value="$(_secrets_keychain_get "$name")" && export "$var=$value"
      done < <(_secrets_entries)
      unset value
      ;;
    *)
      print "usage: secrets {sync [name...] | list | get <name> | rm <name> | export}"
      ;;
  esac
}
