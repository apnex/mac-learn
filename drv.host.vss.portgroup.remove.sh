#!/bin/bash
source mod.core

IPADDR="${1}"
VSWITCH="${2}"
PGROUP="${3}"
ESXPASS=$(jq -r '.esxpass' <parameters)

function sshCmd {
	local COMMANDS="${1}"
	sshpass -p ${ESXPASS} ssh root@${IPADDR} -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "${COMMANDS}"
}

if [[ -n "${IPADDR}" && "${VSWITCH}" && "${PGROUP}" ]]; then
	read -r -d '' COMMANDS <<-EOF
		esxcli network vswitch standard portgroup remove --vswitch-name "${VSWITCH}" --portgroup-name "${PGROUP}"
		esxcli network vswitch standard portgroup list
	EOF
        RESPONSE=$(sshCmd "${COMMANDS}")
	printf "%s\n" "${RESPONSE}"
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "host.vss.portgroup.remove") $(ccyan "<ip-address> <vswitch-name> <pgroup-name>")\n" 1>&2
fi
