#!/bin/bash
source mod.core

# inputs
IPADDR=${1}
ESXPASS=$(jq -r '.esxpass' <parameters)

function sshCmd {
	local COMMANDS="${1}"
	sshpass -p ${ESXPASS} ssh root@${IPADDR} -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "${COMMANDS}"
}

if [[ -n "${IPADDR}" ]]; then
	read -r -d '' COMMANDS <<-EOF
		printf "%s\n" "dvport: 12"
		netdbg vswitch mac-table port get --dvs-alias fabric --dvport 25 2>/dev/null
		printf "%s\n" "dvport: 13"
		netdbg vswitch mac-table port get --dvs-alias fabric --dvport 26 2>/dev/null
		printf "%s\n" "dvport: 14"
		netdbg vswitch mac-table port get --dvs-alias fabric --dvport 27 2>/dev/null
		printf "%s\n" "dvport: 15"
		netdbg vswitch mac-table port get --dvs-alias fabric --dvport 28 2>/dev/null
	EOF
	sshCmd "${COMMANDS}"
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "host.netdbg.instance.list") $(ccyan "<ip-address>")\n" 1>&2
fi
