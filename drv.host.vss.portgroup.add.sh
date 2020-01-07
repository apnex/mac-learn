#!/bin/bash
source mod.core

IPADDR="${1}"
VSWITCH="${2}"
PGROUP="${3}"
VLAN="${4}"
if [[ -z "${VLAN}" ]]; then
	VLAN="0"
fi
ESXPASS=$(jq -r '.esxpass' <parameters)

function sshCmd {
	local COMMANDS="${1}"
	sshpass -p ${ESXPASS} ssh root@${IPADDR} -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "${COMMANDS}"
}

if [[ -n "${IPADDR}" && "${VSWITCH}" && "${PGROUP}" ]]; then
	read -r -d '' COMMANDS <<-EOF
		esxcli network vswitch standard portgroup add --vswitch-name "${VSWITCH}" --portgroup-name "${PGROUP}"
		esxcli network vswitch standard portgroup set --vlan-id "${VLAN}" --portgroup-name "${PGROUP}"
		esxcli network vswitch standard portgroup list
	EOF
        RESPONSE=$(sshCmd "${COMMANDS}")
	printf "%s\n" "${RESPONSE}"
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "host.vss.portgroup.add") $(ccyan "<ip-address> <vswitch-name> <pgroup-name> [ <vlan> ]")\n" 1>&2
fi
