#!/bin/bash
if [[ $0 =~ ^(.*)/[^/]+$ ]]; then
	WORKDIR=${BASH_REMATCH[1]}
fi
source ${WORKDIR}/drv.core

## input driver
INPUT=$(${WORKDIR}/drv.host.vds.list.sh "1")
read -r -d '' INPUTSPEC <<-CONFIG
	.[].DVPort | map({
		"PortID": .PortID,
		"InUse": .InUse,
		"DVPortgroupID": .DVPortgroupID,
		"Client": .Client[0]
	})
CONFIG
NODES=$(echo "$INPUT" | jq -r "$INPUTSPEC")

# build node record
KEY=9
NODE=$(echo ${NODES} | jq -r ".[] | select(.PortID==${KEY})")
printf "%s\n" "${NODE}" 1>&2
