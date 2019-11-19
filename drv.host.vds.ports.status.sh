#!/bin/bash
if [[ $0 =~ ^(.*)/[^/]+$ ]]; then
	WORKDIR=${BASH_REMATCH[1]}
fi
source ${WORKDIR}/drv.core

ID=$1

## input driver
if [[ -n "${ID}" ]]; then
	INPUT=$(${WORKDIR}/drv.host.vds.list.sh "${ID}")
	read -r -d '' INPUTSPEC <<-CONFIG
		.[].DVPort | map({
			"PortID": .PortID,
			"InUse": .InUse,
			"DVPortgroupID": .DVPortgroupID,
			"Client": .Client[0]
		})
	CONFIG
	NODES=$(echo "$INPUT" | jq -r "$INPUTSPEC")
fi

# item status
function getStatus {
	local NODEID=${1}
	if [[ -n "${NODEID}" ]]; then
		#printf "[$(cgreen "INFO")]: vsp [$(cgreen "status")] vds.port [$(cgreen "$NODEID")]... \n" 1>&2
		./drv.host.vds.maclearn.port.get.sh ${ID} fabric "${NODEID}"
	fi
}

function buildNode {
	local KEY=${1}

	read -r -d '' JQSPEC <<-CONFIG # collapse into single line
		.[] | select(.PortID=="${KEY}")
	CONFIG
	local NODE=$(echo ${NODES} | jq -r "$JQSPEC")

	# build node record
	#local NODE=$(echo ${NODES} | jq -r "'.[] | select(.PortID==${KEY})'")
	#printf "%s\n" "${ANODE}" 1>&2

	read -r -d '' NODESPEC <<-CONFIG
		{
			"PortID": .PortID,
			"InUse": .InUse,
			"DVPortgroupID": .DVPortgroupID,
			"Client": .Client
		}
	CONFIG
	BASENODE=$(echo "${NODE}" | jq -r "${NODESPEC}")

	## build node status
	local RESULT=$(getStatus "$KEY")
	read -r -d '' STATUSSPEC <<-CONFIG
		{
			"dvport": .dvport,
			"mac_learning": .mac_learning,
			"unknown_unicast_flooding": .unknown_unicast_flooding,
			"mac_limit": .mac_limit,
			"mac_limit_policy": .mac_limit_policy
		}
	CONFIG
	NODESTAT=$(echo "${RESULT}" | jq -r "${STATUSSPEC}")

	# merge node and status
	FINALNODE="$(echo "${BASENODE}${NODESTAT}" | jq -s '. | add')"
	printf "%s\n" "${FINALNODE}"
}

if [[ -n "${ID}" ]]; then
	FINAL="[]"
	for KEY in $(echo ${NODES} | jq -r '.[] | .PortID'); do
		MYNODE=$(buildNode "${KEY}")
		FINAL="$(echo "${FINAL}[${MYNODE}]" | jq -s '. | add')"
	done
	printf "${FINAL}" | jq --tab .
else
	printf "[$(corange "ERROR")]: command usage: $(cgreen "host.vds.ports.status") $(ccyan "<ip-address>")\n" 1>&2
fi

