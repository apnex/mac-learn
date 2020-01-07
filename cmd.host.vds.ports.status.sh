#!/bin/bash
if [[ $0 =~ ^(.*)/([^/]+)$ ]]; then ## offload to drv.core?
	WORKDIR=${BASH_REMATCH[1]}
	if [[ ${BASH_REMATCH[2]} =~ ^[^.]+[.](.+)[.]sh$ ]]; then
		TYPE=${BASH_REMATCH[1]}
	fi
fi
source ${WORKDIR}/mod.core

## input driver
INPUT=$(${WORKDIR}/drv.host.vds.ports.status.sh "${1}")

## build record structure
read -r -d '' INPUTSPEC <<-CONFIG
	. | map({
		"dvport": .PortID,
		"in_use": .InUse,
		"dv_portgroup_id": .DVPortgroupID,
		"client": .Client,
		"mac_learning": .mac_learning,
		"unknown_unicast_flooding": .unknown_unicast_flooding,
		"mac_limit": .mac_limit,
		"mac_limit_policy": .mac_limit_policy
	})
CONFIG
PAYLOAD=$(echo "$INPUT" | jq -r "$INPUTSPEC")

# build filter
#FILTER=${1}
#FORMAT=${2}
#PAYLOAD=$(filter "${PAYLOAD}" "${FILTER}")

## cache context data record
#setContext "$PAYLOAD" "$TYPE"

## output
case "${FORMAT}" in
	json)
		## build payload json
		echo "${PAYLOAD}" | jq --tab .
	;;
	raw)
		## build input json
		echo "${INPUT}" | jq --tab .
	;;
	*)
		## build payload table
		buildTable "${PAYLOAD}"
	;;
esac
