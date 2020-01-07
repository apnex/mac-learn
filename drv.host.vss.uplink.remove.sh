#!/bin/bash
source mod.core

IPADDR="${1}"
NIC="${2}"
SWITCH="${3}"
ESXPASS=$(jq -r '.esxpass' <parameters)

function sshCmd {
	local COMMANDS="${1}"
	sshpass -p ${ESXPASS} ssh root@"${IPADDR}" -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "${COMMANDS}"
}

if [[ -n "${IPADDR}" && "${NIC}" && "${SWITCH}" ]]; then
	read -r -d '' COMMANDS <<-EOF
		esxcli network vswitch standard uplink remove --vswitch-name "${SWITCH}" --uplink-name "${NIC}"
	EOF
	#esxcli network vswitch standard list
	sshCmd "${COMMANDS}"
	./drv.host.vss.list.sh "${IPADDR}"
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "node.interface.list") $(ccyan "<ip-address> <nic> <vswitch>")\n" 1>&2
fi
