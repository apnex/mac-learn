#!/bin/bash
source mod.core

# inputs
IPADDR="${1}"
ESXPASS=$(jq -r '.esxpass' <parameters)

function sshCmd {
	local COMMANDS="${1}"
	sshpass -p ${ESXPASS} ssh root@${IPADDR} -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "${COMMANDS}"
}

if [[ -n "${IPADDR}" ]]; then
	read -r -d '' COMMANDS <<-EOF
		esxcli network vswitch standard portgroup list
	EOF
	#	esxcli --formatter=keyvalue network vswitch standard list
        RESPONSE=$(sshCmd "${COMMANDS}")
	printf "${RESPONSE}\n"
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "host.vss.portgroup.list") $(ccyan "<ip-address>")\n" 1>&2
fi
