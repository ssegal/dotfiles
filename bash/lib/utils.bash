# shellcheck shell=bash

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This file is intended to be sourced." >&2
    exit 1
fi

command_exists() {
    # Test result with || to avoid triggering errexit.
    command -v "$1" &> /dev/null || return 1
    return 0
}

source_if_exists() {
    # shellcheck disable=SC1090
    [[ -r $1 ]] && source -- "$@"
}

dedup_path_var() {
    local var_name="$1"
    # Get the current value of the variable dynamically
    local current_val="${!var_name}"
    
    # Do nothing if the variable is empty
    [[ -z "$current_val" ]] && return

    # Filter and update the variable globally
    eval "export $var_name=\$(echo -n \"\$current_val\" | awk -v RS=: '!(\$0 in a) {a[\$0]; printf(\"%s%s\", length(a) > 1 ? \":\" : \"\", \$0)}')"
}
