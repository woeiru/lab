# Network Topology Graph

```mermaid
graph TD
    INT[Internet] --- ISPR[ISP Router]
    ISPR -.- US
    US{{Unmanaged Switch}} -.- MH1
    OPN((OpenSENSE)) --- VB((VIRTUAL BRIDGE))
    GIT((GITEA)) --- VB
    VB --- QDV((Quorum Device))
    VB --- QDD((Quorum Device))
    VB ===|2x 10g| CS{{Core Switch}}
    MH1[(Mgmt Hypervisor 1)] -.-  MS{{Mgmt Switch}}
    MH2[(Mgmt Hypervisor 2)] -.-  MS{{Mgmt Switch}}
    QDM[(Quorum Device)] -.-  MS{{Mgmt Switch}}
    MS --- CS
    MS -- |1g| APC[Admin PC]
    APC -- |wifi|  ISPR
    MH1 ==>|Hosts| VB
    CS -- |10g| VH2[(VFIO Hypervisor 2)]
    MS -- |1g| VH2
    US -- |10g| GD[Guest Devices]
    CS -- |10g| VH1[(VFIO Hypervisor 1)]
    MS -- |1g| VH1
    CS -- |10g| DH1[(Data Hypervisor 1)]
    MS -- |1g| DH1
    CS -- |10g| DH2[(Data Hypervisor 2)]
    MS -- |1g| DH2
    VH1 -- |25g| DH1
    subgraph VLAN20 [DATA VLAN 20]
        DH1
        DH2
        QDD
    end
    subgraph VLAN30 [VFIO VLAN 30]
        VH1
        VH2
        QDV
    end
    subgraph VLAN99 [Non-Routable Management VLAN 99]
        MS
        OPN
        GIT
    end
    subgraph DMZ [DMZ-like Area / Wi-Fi]
        ISPR
        GD
        US
    end
```
