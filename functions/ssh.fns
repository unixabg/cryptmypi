assure_box_sshkey(){
    _KEYFILE="${_CONFDIR}/id_rsa"

    echo_debug "    Asserting box ssh keyfile:"
    test -f "${_KEYFILE}" && {
        echo_debug "    - Keyfile ${_KEYFILE} already exists!"
    } || {
        echo_debug "    - Keyfile ${_KEYFILE} does not exists. Generating ..."
        ssh-keygen -q -t rsa -N '' -f "${_KEYFILE}" 2>/dev/null <<< y >/dev/null
        chmod 600 "${_KEYFILE}"
        chmod 644 "${_KEYFILE}.pub"
    }

    echo_debug "    - Copying keyfile ${_KEYFILE} to box's default user .ssh directory ..."
    cp "${_KEYFILE}" "${CHROOTDIR}/root/.ssh/id_rsa"
    cp "${_KEYFILE}.pub" "${CHROOTDIR}/root/.ssh/id_rsa.pub"
    chmod 600 "${CHROOTDIR}/root/.ssh/id_rsa"
    chmod 644 "${CHROOTDIR}/root/.ssh/id_rsa.pub"
}

backup_and_use_sshkey(){
    local _TMP_KEYPATH=$1
    local _TMP_KEYNAME=$(basename ${_TMP_KEYPATH})

    test -f "${_CONFDIR}/${_TMP_KEYNAME}" && {
        cp "${_CONFDIR}/${_TMP_KEYNAME}" "${_TMP_KEYPATH}"
        chmod 600 "${_TMP_KEYPATH}"
    } || {
        cp "${_TMP_KEYPATH}" "${_CONFDIR}/${_TMP_KEYNAME}"
    }
}