# ipadd
# tn.id
# 

## reverse
# remove vmnic0 to hs-fabric
cmd.transport-nodes.uplinks.remove.sh 9c442210-85cb-4407-875f-a31a3818ace0 vmnic0

# add vmnic0 to vSwitch0
drv.host.vss.uplink.add.sh 172.16.10.102 vmnic0 vSwitch0

# migrate vmk0 to vss-mgmt port-group
cmd.host.vmk.migrate.sh 9c442210-85cb-4407-875f-a31a3818ace0 vss-mgmt

# remove vmnic1 from vSwitch0
drv.host.vss.uplink.remove.sh 172.16.10.101 vmnic1 vSwitch0

# add vmnic1 to hs-fabric
cmd.transport-nodes.uplinks.modify.sh 5ef2ca1c-fe79-4faa-afef-b965622b85c7 vmnic1 uplink2
