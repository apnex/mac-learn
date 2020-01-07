# ipadd
# tn.id
# 

## forward
# remove vmnic1 from vSwitch0
drv.host.vss.uplink.remove.sh 172.16.10.101 vmnic0 vSwitch0

# add vmnic0 to hs-fabric
cmd.transport-nodes.uplinks.modify.sh 5ef2ca1c-fe79-4faa-afef-b965622b85c7 vmnic0 uplink1

# migrate vmk0 to hs-fabric logical-switch
cmd.host.vmk.migrate.sh 5ef2ca1c-fe79-4faa-afef-b965622b85c7 a673b535-4b68-464a-8e53-0617492dc93d

# remove vmnic1 from vSwitch0
drv.host.vss.uplink.remove.sh 172.16.10.101 vmnic1 vSwitch0

# add vmnic1 to hs-fabric
cmd.transport-nodes.uplinks.modify.sh 5ef2ca1c-fe79-4faa-afef-b965622b85c7 vmnic1 uplink2
