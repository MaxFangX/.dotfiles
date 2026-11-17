# Not a module: a helper that returns the shell function `secret NAME`,
# which prints NAME's value from ~/env/sensitive.sh, or nothing if it is
# unset. That file exports every secret, so the function sources it in a
# subshell, and the caller's environment gets only what it asks for.
{ config }:
let
  envFile = "${config.home.homeDirectory}/env/sensitive.sh";
in
''
  secret() {
    [ -f "${envFile}" ] || return 0
    # shellcheck disable=SC1091
    (set +u; . "${envFile}"; printf '%s' "''${!1-}")
  }
''
