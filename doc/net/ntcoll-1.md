<!--
#######################################################################
# Network Topology Documentation - Collection 1
#######################################################################
# File: /home/es/lab/doc/net/ntcoll-1.md
# Description: Comprehensive network topology visualization and
#              documentation using Mermaid diagrams for lab environment
#              infrastructure mapping and connectivity analysis.
#
# Author: Network Architecture Team
# Created: 2025-05-28
# Updated: 2025-05-28
# Version: 1.0.0
# Category: Technical Documentation - Network
#
# Document Purpose:
#   Provides detailed network topology diagrams and connectivity
#   documentation for understanding infrastructure layout, device
#   relationships, and network flow within the lab environment.
#
# Technical Scope:
#   - Management hypervisor network configurations
#   - PCIe passthrough networking setups
#   - Inter-device connectivity mapping
#   - Network interface card assignments
#
# Target Audience:
#   Network engineers, infrastructure architects, and system
#   administrators responsible for network planning, troubleshooting,
#   and infrastructure maintenance in virtualized environments.
#
# Dependencies:
#   - Mermaid diagram rendering support
#   - Network infrastructure components
#   - Hypervisor platform configurations
#######################################################################
-->

# Network Topology Graphs

```mermaid
graph TD
    subgraph MH1[Management Hypervisor 1]
        MH1NIC1[intel NIC]
        MH1NIC2[intel NIC]
        MH1NIC3[mellanox NIC]
        MH1NIC4[mellanox NIC]
        MH1NIC3 -.-|"PCIE PT"| OPN
        MH1NIC4 -.-|"PCIE PT"| OPN
        VB2{Virtual Bridge 2}
        MH1NIC2 ---|"Bound"| VB2
        OPN((OpenSENSE))
        QDV((Quorum Device VFIO))
        QDD((Quorum Device DATA))
        GIT((GITEA))
        MH1TEAM(TEAM)
    end

    INT[Internet] -.-> |WAN| ISPR[ISP Router]
    ISPR --- |"1G"| US{{Unmanaged Switch}}
    US --- GD[Guest Devices]
    US ---|1G| MH1NIC1

    MS{{Mgmt Switch}} ---|"1G"| APC[Admin PC]
    APC ---|"1G"| US

    MH1NIC2 ---|"1G"| MS
    MH1NIC3 ---|"10G"| MH1TEAM
    MH1NIC4 ---|"10G"| MH1TEAM
    MH1TEAM ===|"10G"| CS{{Core Switch}}

    MS --->|"10G"| CS
    MS --->|"1G"| DH1
    MS --->|"1G"| DH2
    MS --->|"1G"| VH1
    MS --->|"1G"| VH2

    CS ---|"10G"| DH1[(DATA Hypervisor 1)]
    CS ---|"10G"| DH2[(DATA Hypervisor 2)]
    CS ---|"10G"| VH1[(VFIO Hypervisor 1)]
    CS ---|"10G"| VH2[(VFIO Hypervisor 2)]

    VH1 -.-|"25g optional"| DH1
    VH2 -.-|"25g optional"| DH2

    CS ---|"10g"| BMS{{Baremetal Switch}}
    BMS ---|"10g"| BM1[Baremetal Machine 1]
    BMS ---|"2.5g"| BM2[Baremetal Machine 2]
    BMS ---|"2.5g"| BM3[Baremetal Machine 3]

    subgraph VLAN20 [DATA VLAN 20]
        DH1
        DH2
    end
    subgraph VLAN30 [VFIO VLAN 30]
        VH1
        VH2
    end
    subgraph VLAN40 [BARE VLAN 40]
        BMS
        BM1 
        BM2 
        BM3 
    end
    subgraph VLAN99 [Mgmt VLAN 99]
        MH1
        MS
    end
    subgraph Guest [Guest / Wi-Fi]
        ISPR
        GD
        US
    end

    VB2 -.-|VLAN 20| QDD
    VB2 -.-|VLAN 30| QDV
    VB2 -.-|VLAN 99| GIT

    classDef punctuated stroke-dasharray: 5 5;
    class TEAM,GIT,QDV,QDD,OPN punctuated;
    classDef vlan fill:#f9f,stroke:#333,stroke-width:2px;
    class VLAN20,VLAN30,VLAN40,VLAN99 vlan;
```

```mermaid
graph TD
    subgraph MH1[Management Hypervisor 1]
        MH1NIC1[intel NIC]
        MH1NIC2[intel NIC]
        MH1NIC3[mellanox NIC]
        MH1NIC4[mellanox NIC]
        MH1NIC3 -.-|"PCIE PT"| OPN1
        MH1NIC4 -.-|"PCIE PT"| OPN1
        VB2_1{Virtual Bridge 2}
        MH1NIC2 ---|"Bound"| VB2_1
        OPN1((OpenSENSE 1))
        QDV1((Quorum Device VFIO))
        QDD1((Quorum Device DATA))
        GIT1((GITEA 1))
        MH1TEAM(TEAM)
    end

    subgraph MH2[Management Hypervisor 2]
        MH2NIC1[intel NIC]
        MH2NIC2[intel NIC]
        MH2NIC3[mellanox NIC]
        MH2NIC4[mellanox NIC]
        MH2NIC3 -.-|"PCIE PT"| OPN2
        MH2NIC4 -.-|"PCIE PT"| OPN2
        VB2_2{Virtual Bridge 2}
        MH2NIC2 ---|"Bound"| VB2_2
        OPN2((OpenSENSE 2))
        QDV2((Quorum Device VFIO))
        QDD2((Quorum Device DATA))
        GIT2((GITEA 2))
        MH2TEAM(TEAM)
    end

    INT[Internet] -.-> |WAN| ISPR[ISP Router]
    ISPR --- |"1G"| US{{Unmanaged Switch}}
    US --- GD[Guest Devices]
    US ---|1G| MH1NIC1
    US ---|1G| MH2NIC1
    MS{{Mgmt Switch}} ---|"1G"| APC[Admin PC]
    APC ---|"1G"| US
    MH1NIC2 ---|"1G"| MS
    MH2NIC2 ---|"1G"| MS
    MH1NIC3 ---|"10G"| MH1TEAM
    MH1NIC4 ---|"10G"| MH1TEAM
    MH2NIC3 ---|"10G"| MH2TEAM
    MH2NIC4 ---|"10G"| MH2TEAM
    MH1TEAM ===|"10G"| CS{{Core Switch}}
    MH2TEAM ===|"10G"| CS
    MS --->|"10G"| CS
    MS --->|"1G"| DH1
    MS --->|"1G"| DH2
    MS --->|"1G"| VH1
    MS --->|"1G"| VH2
    CS ---|"10G"| DH1[(DATA Hypervisor 1)]
    CS ---|"10G"| DH2[(DATA Hypervisor 2)]
    CS ---|"10G"| VH1[(VFIO Hypervisor 1)]
    CS ---|"10G"| VH2[(VFIO Hypervisor 2)]
    VH1 -.-|"25g optional"| DH1
    VH2 -.-|"25g optional"| DH2
    CS ---|"10g"| BMS{{Baremetal Switch}}
    BMS ---|"10g"| BM1[Baremetal Machine 1]
    BMS ---|"2.5g"| BM2[Baremetal Machine 2]
    BMS ---|"2.5g"| BM3[Baremetal Machine 3]

    subgraph VLAN20 [DATA VLAN 20]
        DH1
        DH2
    end
    subgraph VLAN30 [VFIO VLAN 30]
        VH1
        VH2
    end
    subgraph VLAN40 [BARE VLAN 40]
        BMS
        BM1
        BM2
        BM3
    end
    subgraph VLAN99 [Mgmt VLAN 99]
        MH1
        MH2
        MS
    end
    subgraph Guest [Guest / Wi-Fi]
        ISPR
        GD
        US
    end

    VB2_1 -.-|VLAN 20| QDD1
    VB2_1 -.-|VLAN 30| QDV1
    VB2_1 -.-|VLAN 99| GIT1
    VB2_2 -.-|VLAN 20| QDD2
    VB2_2 -.-|VLAN 30| QDV2
    VB2_2 -.-|VLAN 99| GIT2

    classDef punctuated stroke-dasharray: 5 5;
    class MH1TEAM,MH2TEAM,GIT1,QDV1,QDD1,OPN1,GIT2,QDV2,QDD2,OPN2 punctuated;
    classDef vlan fill:#f9f,stroke:#333,stroke-width:2px;
    class VLAN20,VLAN30,VLAN40,VLAN99 vlan;
```

```mermaid
graph TD
    subgraph Internet
        INT((Internet))
    end

    subgraph "Site A"
        ISPA[ISP Router A]
        MH1[Management Hypervisor 1]
        VH1[VFIO Hypervisor 1]
        DH1[Data Hypervisor 1]
        CSA{Core Switch A}
        MSA{Mgmt Switch A}

        subgraph MH1
            OPN1((OpenSENSE 1))
            VB2_1{Virtual Bridge 2}
        end

        ISPA ---|WAN| MH1
        OPN1 ---|LAN| CSA
        MH1 --- MSA
        CSA --- VH1
        CSA --- DH1
        MSA --- VH1
        MSA --- DH1
    end

    subgraph "Site B"
        ISPB[ISP Router B]
        MH2[Management Hypervisor 2]
        VH2[VFIO Hypervisor 2]
        DH2[Data Hypervisor 2]
        CSB{Core Switch B}
        MSB{Mgmt Switch B}

        subgraph MH2
            OPN2((OpenSENSE 2))
            VB2_2{Virtual Bridge 2}
        end

        ISPB ---|WAN| MH2
        OPN2 ---|LAN| CSB
        MH2 --- MSB
        CSB --- VH2
        CSB --- DH2
        MSB --- VH2
        MSB --- DH2
    end

    OPN1 -.-|VPN Tunnel| INT
    OPN2 -.-|VPN Tunnel| INT

    classDef hypervisor fill:#f9f,stroke:#333,stroke-width:2px;
    class MH1,MH2,VH1,VH2,DH1,DH2 hypervisor;
    classDef virtual stroke-dasharray: 5 5;
    class OPN1,OPN2,VB2_1,VB2_2 virtual;
```

```mermaid
graph TD
    INT[Internet] -.-> |WAN| ISPR[ISP Router]
    ISPR --- |"1G"| US{{Unmanaged Switch}}
    US --- GD[Guest Devices]
    US ---|1G| MH1[Management Hypervisor 1]
    US ---|1G| MH2[Management Hypervisor 2]
    US -.-|"2.5G Optional"| TS{{Test Switch}}

    US ---|"Wifi"| AP[Admin Baremetal]
    AP ---|"2.5G"| MS{{Mgmt Switch}}

    MH1 ---|"1G"| MS
    MH2 ---|"1G"| MS
    MH1 ---|"10G"| CS{{Core Switch}}
    MH2 ---|"10G"| CS

    MS ---|"10G"| CS
    MS --->|"1G"| DH1
    MS --->|"1G"| DH2
    MS --->|"1G"| VH1
    MS --->|"1G"| VH2

    CS ---|"10G"| DH1[(DATA Hypervisor 1)]
    CS ---|"10G"| DH2[(DATA Hypervisor 2)]
    CS ---|"10G"| VH1[(VFIO Hypervisor 1)]
    CS ---|"10G"| VH2[(VFIO Hypervisor 2)]

    VH1 -.-|"25G optional"| DH1
    VH2 -.-|"25G optional"| DH2

    CS ---|"10G"| TS
    TS ---|"10G"| TH[Test Hypervisor]
    TS -.-|"1G Optional"| TH
    TS ---|"2.5G"| TM[Test Baremetal]

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
        MH1
        MH2
        MS
    end
    subgraph Guest [Guest / Wi-Fi]
        ISPR
        GD
        US
    end

    classDef vlan fill:#f9f,stroke:#333,stroke-width:2px;
    class VLAN20,VLAN30,VLAN99 vlan;

    classDef vlan fill:#e9e,stroke:#333,stroke-width:2px;
    class VLAN99 vlan;

    classDef hybridtestnet fill:#9f9,stroke:#333,stroke-width:2px;
    class VLAN10 hybridtestnet;

    classDef optional stroke-dasharray: 5 5;
    class US,TH optional;

    classDef adminpc fill:#f96,stroke:#333,stroke-width:4px;
    class AP adminpc;

    classDef testmachine fill:#ff9,stroke:#333,stroke-width:2px;
    class TM testmachine;
```
```mermaid
graph TD
    INT[Internet] --- |WAN| ISPR[ISP Router]
    US --- |"1G"| CS2{{Core Switch 2}}
    ISPR ---|"2.5G"| US{{Unmanaged Switch}}
    US ---|"2.5G"| GD[Guest Device 1]
    CS2{{Core Switch 2}} ---|"2.5G"| AP[Admin PC]
    CS2 ---|"1G"| MH1NIC3[MH1 VLAN99 NIC]
    CS2 ---|"1G"| MH2NIC3[MH2 VLAN99 NIC]
    CS2 ---|"1G"| DH1
    CS2 ---|"1G"| DH2
    CS2 ---|"1G"| VH1
    CS2 ---|"1G"| VH2
    MH1NIC2[MH1 Core NIC] ---|"10G"| CS1
    MH2NIC2[MH2 Core NIC] ---|"10G"| CS2
    CS1 ---|"10G"| DH1[(DATA Hypervisor 1)]
    CS1 ---|"10G"| DH2[(DATA Hypervisor 2)]
    CS1 ---|"10G"| VH1[(VFIO Hypervisor 1)]
    CS1 ---|"10G"| VH2[(VFIO Hypervisor 2)]
    VH1 -.-|"25G optional"| DH1
    VH2 -.-|"25G optional"| DH2
    CS2 ---|"10G"| TS{{Test Switch}}
    TS ---|"10G"| TH[Test Hypervisor]
    TS -.-|"2.5G Optional"| TH
    TS ---|"2.5G"| TM[Test PC]
    subgraph MH1[Management Hypervisor 1]
        MH1NIC2 ---|"PCIE PT"| OPN1((OpenSense VM 1))
        MH1NIC3 ---|"Virtual Bridge"| OPN1
    end
    subgraph MH2[Management Hypervisor 2]
        MH2NIC2 ---|"PCIE PT"| OPN2((OpenSense VM 2))
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
        CS2
        AP
        MH1NIC3
        MH2NIC3
    end
    subgraph Guest [Guest / Wi-Fi DMZ]
        INT
        ISPR
        US
        GD
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

```mermaid
graph TD
    INT[Internet] --- |WAN| ISPR[ISP Router]
    ISPR --- |"1G"| US{{Unmanaged Switch}}
    US ---|"2.5G"| GD[Guest Device 1]
    US ---|"2.5G"| MS{{Mgmt Switch}}
    US -.-|"2.5G Optional"| TS{{Test Switch}}

    AP ---|"2.5G"| MS
    MS ---|"10G"| MH1NIC1[MH1 Mgmt NIC]
    MS ---|"10G"| MH2NIC1[MH2 Mgmt NIC]
    MS ---|"1G"| MH1NIC3[MH1 WAN NIC]
    MS ---|"1G"| MH2NIC3[MH2 WAN NIC]
    MS ---|"1G"| MH1NIC4[MH1 VLAN99 NIC]
    MS ---|"1G"| MH2NIC4[MH2 VLAN99 NIC]

    MH1NIC2[MH1 Core NIC] ---|"10G"| CS{{Core Switch}}
    MH2NIC2[MH2 Core NIC] ---|"10G"| CS
    MS ---|"10G"| CS
    MS ---|"1G"| DH1
    MS ---|"1G"| DH2
    MS ---|"1G"| VH1
    MS ---|"1G"| VH2
    CS ---|"10G"| DH1[(DATA Hypervisor 1)]
    CS ---|"10G"| DH2[(DATA Hypervisor 2)]
    CS ---|"10G"| VH1[(VFIO Hypervisor 1)]
    CS ---|"10G"| VH2[(VFIO Hypervisor 2)]
    VH1 -.-|"25G optional"| DH1
    VH2 -.-|"25G optional"| DH2
    CS ---|"10G"| TS
    TS ---|"10G"| TH[Test Hypervisor]
    TS -.-|"2.5G Optional"| TH
    TS ---|"2.5G"| TM[Test PC]

    subgraph MH1[Management Hypervisor 1]
        MH1NIC1 & MH1NIC2 & MH1NIC3 ---|"PCIE PT"| OPN1((OpenSense VM))
        MH1NIC4 ---|"Virtual Bridge"| OPN1
    end

    subgraph MH2[Management Hypervisor 2]
        MH2NIC1 & MH2NIC2 & MH2NIC3 ---|"PCIE PT"| OPN2((OpenSense VM))
        MH2NIC4 ---|"Virtual Bridge"| OPN2
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
        AP[Admin PC]
        MH1NIC4
        MH2NIC4
    end
    subgraph Guest [Guest / Wi-Fi]
        ISPR
        GD
        US
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
```
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
```mermaid
graph TD
    INT[Internet] --- |WAN| ISPR[ISP Router]
    US --- |"2.5G"| CS{{Core Switch}}
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
    DH1 ---|"25G"| DH2[(DATA Hypervisor 2<br>Cold Standby)]
    DH2 ---|"10G"| MS
    CS ---|"10G"| VH1[(VFIO Hypervisor 1)]
    CS ---|"10G"| VH2[(VFIO Hypervisor 2)]
    CS ---|"10G"| TS{{Test Switch}}
    TS ---|"10G"| TH[Test Hypervisor]
    TS -.-|"2.5G Optional"| TH
    TS ---|"2.5G"| TM[Test PC]
    VBA{Virtual Bridge A} -..- QDD((QDev Data))
    VBA{Virtual Bridge A} -..- QDV((QDev VFIO))

    subgraph MH1[Meta Hypervisor 1]
        MH1NIC2 ---|"PCIE PT"| OPN1((OpenSense VM 1))
        MH1NIC3
    end
        MH1NIC3 --- VBA

    subgraph MH2[Meta Hypervisor 2]
        MH2NIC2 ---|"PCIE PT"| OPN2((OpenSense VM 2))
        MH2NIC3
    end
        MH2NIC3 --- VBA

    subgraph VLAN20 [DATA VLAN 20]
        DH1
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
        DH2
        QDD
        QDV
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

    classDef metahypervisor fill:#ffe6cc,stroke:#333,stroke-width:2px;
    class MH1,MH2,VBA metahypervisor;

    classDef optional stroke-dasharray: 5 5;
    class US optional;

    classDef adminpc fill:#f96,stroke:#333,stroke-width:4px;
    class AP adminpc;

    classDef testmachine fill:#ff9,stroke:#333,stroke-width:2px;
    class TM testmachine;

    classDef dmz fill:#ffd700,stroke:#333,stroke-width:2px;
    class Guest dmz;

    classDef quorum fill:#ff7f50,stroke:#333,stroke-width:2px;
    class QDD quorum;

    classDef coldstandby fill:#c0c0c0,stroke:#333,stroke-width:2px;
    class DH2 coldstandby;
 ```

