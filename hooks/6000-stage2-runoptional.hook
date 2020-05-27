#!/bin/bash
set -e


# Runs configuration optional hooks
echo_info "Checking if configuration profile defines optional hook function ..."
function_exists "stage2_optional_hooks" && {
    echo_info ""
    echo_info "--- Optional hooks found:"
    function_summary stage2_optional_hooks
    echo_info ""
    echo_info "### OPTIONAL HOOKS ################################################ STAGE 2 ###"
    stage2_optional_hooks
    echo_info "######################################################## OPTIONAL HOOKS END ###"
    echo_info ""
} || {
    echo_warn "- SKIPPING: optional hooks on stage 2 ..."
    cat << EOF

        To define optional hooks, create a function named
        'stage2_optional_hooks' on the cryptmypi.conf file.

EOF
}
