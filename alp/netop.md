# Network Topology Graph

```mermaid
graph TD
<<<<<<< HEAD
<<<<<<< HEAD
=======
    %% Define styles
    classDef default fill:#f9f9f9,stroke:#333,stroke-width:2px;
    classDef network fill:#e1f5fe,stroke:#01579b,stroke-width:2px;
    classDef hypervisor fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px;
    classDef vm fill:#fff3e0,stroke:#e65100,stroke-width:2px;
    classDef vlan fill:#f3e5f5,stroke:#4a148c,stroke-width:2px;

>>>>>>> parent of ad31816 (standard)
    %% External Network
    subgraph EXT [External Network]
        INT[Internet]
        ISPR[ISP Router]
        US[Unmanaged Switch]
        GD[Guest Devices]
=======
    INT[Internet] -.-> |WAN| ISPR[ISP Router]
    ISPR ---> |LAN| US
    US{{Unmanaged Switch}} -.-> |LAN| MH1
    US -.-> |LAN| MH2
    VB1{Virtual Bridge 1} -.- |"Uses VB1"| QDV((Quorum Device VFIO))
    VB1 -.- |"Uses VB1"| QDD((Quorum Device Data))
    VB1 -.- |"Uses VB1"| OPN((OpenSENSE))
    OPN ===|"2x 10G"| CS{{Core Switch}}
    MH1[(Mgmt Hypervisor 1)] -.-> |"1G"| MS{{Mgmt Switch}}
    MH2[(Mgmt Hypervisor 2)] ---> |"10G"| MS
    MS --- |"10G"| CS
    MS ---|"1G"| APC[Admin PC]
    APC ---|"1G"| US
    MH1 ==>|"Hosts"| VB1
    MH2 ==>|"Hosts"| VB1
    MH1 ==>|"Hosts"| VB2{Virtual Bridge 2}
    MH2 ==>|"Hosts"| VB2
    VB2 -.- |"Uses VB2"| GIT((GITEA))
    VB2 ---> |"Connected to"| MS
    CS ---|"10G"| VH2[(VFIO Hypervisor 2)]
    MS -.->|"1G"| VH2
    US ---|"10G"| GD[Guest Devices]
    CS ---|"10G"| VH1[(VFIO Hypervisor 1)]
    MS --->|"1G"| VH1
    CS ---|"10G"| DH1[(Data Hypervisor 1)]
    MS --->|"1G"| DH1
    CS ---|"10G"| DH2[(Data Hypervisor 2)]
    MS --->|"1G"| DH2
    VH1 ---|"25G"| DH1
    subgraph VLAN20 [DATA VLAN 20]
        DH1
        DH2
        QDD
>>>>>>> parent of f98b0e6 (standard)
    end
    subgraph VLAN30 [VFIO VLAN 30]
        VH1
        VH2
        QDV
    end
    subgraph VLAN99 [Non-Routable Management VLAN 99]
        MS
        GIT
    end
    subgraph DMZ [DMZ-like Area / Wi-Fi]
        ISPR
        GD
        US
    end
    classDef punctuated stroke-dasharray: 5 5;
    class US,MH1,MH2,VH1,VH2,DH1,DH2,GIT,QDV,QDD,OPN punctuated;
```
