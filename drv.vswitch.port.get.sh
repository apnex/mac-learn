#!/bin/bash
source drv.core

# inputs
ID="${1}"
VDSNAME="${2}"
DVPORT="${3}"

function sshCmd {
	local COMMANDS="${1}"
	sshpass -p 'VMware1!' ssh root@"${ID}" -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t "${COMMANDS}"
}

#structure[0].VDS.DVPort.structure[2].DVPort.Client.string[0].string=boot.lab.eth1
#structure[0].VDS.DVPort.structure[2].DVPort.DVPortgroupID.string=dvportgroup-24
#structure[0].VDS.DVPort.structure[2].DVPort.InUse.boolean=true
#structure[0].VDS.DVPort.structure[2].DVPort.PortID.string=9

function makeBody {
	local IFS=$'\n'
	local RESPONSE=(${@})
	NODE="[]"
	for KEY in "${RESPONSE[@]}"; do
		#if [[ $KEY =~ ([A-Za-z0-9][^:]*):[[:space:]]*([-$, A-Za-z0-9]*) ]]; then # grabs key:pair
		#if [[ $KEY =~ structure\[.\].VDS.DVPort.([-= .\\[\\]A-Za-z0-9]*) ]]; then
		#if [[ $KEY =~ structure....VDS.DVPort.(structure....DVPort.InUse.boolean\=true).* ]]; then
		if [[ $KEY =~ structure....VDS.DVPort.([structure....DVPort.InUse.boolean\=true).* ]]; then
			# convert key to lower case and replace spaces with underline
			#local ITEM=$(printf '%s' "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
			local VALUE=$(printf '%s' "${BASH_REMATCH[1]}")
			RECORD="[\"${VALUE}\"]"
			#printf "%s\n" "${RECORD}"
			printf "%s\n" "${VALUE}"
			#NODE="$(echo "${NODE}${RECORD}" | jq -s '. | add')"
		fi
	done
	printf "${NODE}" | jq --tab .
}

if [[ -n "${ID}" ]]; then
	RESPONSE=$(
		read -r -d '' COMMANDS <<-EOF
			esxcli --formatter=keyvalue network vswitch dvs vmware list
		EOF
		sshCmd "${COMMANDS}"
	)
	makeBody "${RESPONSE}"
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "host.switch.list") $(ccyan "<ip-address> <vds-name> <dvport>")\n" 1>&2
fi
