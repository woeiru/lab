# Network Topology Graph

```mermaid
graph TD
    INT[Internet] --- |WAN| ISPR[ISP Router]
    ISPR --- |"1G"| CS{{Core Switch}}
    ISPR ---|"2.5G"| US{{Unmanaged Switch}}
    US ---|"2.5G"| GD[Guest Device 1]
    CS ---|"10G"| MS{{Mgmt Switch}}
    AP[Admin PC] ---|"2.5G"| MS
    MS ---|"1G"| MH1NIC3[MH1 VLAN99 NIC]
    MS ---|"1G"| MH2NIC3[MH2 VLAN99 NIC]
    MS ---|"1G"| DH1
    MS ---|"1G"| DH2
    MS ---|"1G"| VH1
    MS ---|"1G"| VH2
    MH1NIC2[MH1 Core NIC] ---|"10G"| CS
    MH2NIC2[MH2 Core NIC] ---|"10G"| CS
    CS ---|"10G"| DH1[(DATA Hypervisor 1)]
    DH1 ---|"25G"| DH2[(DATA Hypervisor 2)]
    CS ---|"10G"| VH1[(VFIO Hypervisor 1)]
    CS ---|"10G"| VH2[(VFIO Hypervisor 2)]
    VH1 -.-|"25G optional"| DH1
    VH2 -.-|"25G optional"| DH2
    CS ---|"10G"| TS{{Test Switch}}
    TS ---|"10G"| TH[Test Hypervisor]
    TS -.-|"2.5G Optional"| TH
    TS ---|"2.5G"| TM[Test PC]
    subgraph MH1[Management Hypervisor 1]
        MH1NIC2 ---|"PCIE PT"| OPN1((OpenSense VM))
        MH1NIC3 ---|"Virtual Bridge"| OPN1
    end
    subgraph MH2[Management Hypervisor 2]
        MH2NIC2 ---|"PCIE PT"| OPN2((OpenSense VM))
        MH2NIC3 ---|"Virtual Bridge"| OPN2
    end
    subgraph VLAN20 [DATA VLAN 20]
        DH1
        DH2
    end
    subgraph VLAN30 [VFIO VLAN 30]
        VH1
        VH2
    end
    subgraph VLAN10 [Hybrid Test Network / VLAN 10]
        TS
        TH
        TM
    end
    subgraph VLAN99 [Mgmt VLAN 99]
        MS
        AP
        MH1NIC3
        MH2NIC3
    end
    subgraph Guest [Guest / Wi-Fi DMZ]
        US
        GD
        ISPR
    end
    classDef vlan fill:#f9f,stroke:#333,stroke-width:2px;
    class VLAN20,VLAN30 vlan;
    classDef vlan99 fill:#e6f3ff,stroke:#333,stroke-width:2px;
    class VLAN99 vlan99;
    classDef hybridtestnet fill:#9f9,stroke:#333,stroke-width:2px;
    class VLAN10 hybridtestnet;
    classDef mghypervisor fill:#ffe6cc,stroke:#333,stroke-width:2px;
    class MH1,MH2 mghypervisor;
    classDef optional stroke-dasharray: 5 5;
    class US optional;
    classDef adminpc fill:#f96,stroke:#333,stroke-width:4px;
    class AP adminpc;
    classDef testmachine fill:#ff9,stroke:#333,stroke-width:2px;
    class TM testmachine;
    classDef dmz fill:#ffd700,stroke:#333,stroke-width:2px;
    class Guest dmz;
 ```
