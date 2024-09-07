mermaid
```
graph TD
    INT[Internet] --- |WAN| ISPR[ISP Router]
    ISPR ---|"2.5G"| CS{Core Switch}
    CS ---|"10G"| MS{Mgmt Switch}
    AP[Admin PC] ---|"1G"| MS
    AP -.-|"WiFi"| ISPR
    CS ---|"10G"| VS
    CS ---|"10G"| TS
    
    subgraph MetaInfrastructure [Meta Infrastructure]
        CS
        subgraph MH1[Meta Hypervisor 1]
            MH1NICA[MH1 NIC A]
            MH1NICB[MH1 NIC B]
            MH1NICC[MH1 NIC C]
            MH1NICD[MH1 NIC D]
        end
        subgraph MH2[Meta Hypervisor 2]
            MH2NICA[MH2 NIC A]
            MH2NICB[MH2 NIC B]
            MH2NICC[MH2 NIC C]
            MH2NICD[MH2 NIC D]
        end
        VBA[[Virtual Bridge A]]
        VBB[[Virtual Bridge B]]
        OPN((OpenSense VM))
        QDD((QDev Data))
        QDV((QDev VFIO))
        
        VBA --- QDD
        VBA --- QDV
        VBA --- MH1NICB
        VBA --- MH2NICB
        VBB --- OPN
        VBB --- MH1NICC
        VBB --- MH2NICC
    end
    
    subgraph DataInfrastructure [Data Infrastructure]
        subgraph VLAN20 [DATA VLAN 20]
            subgraph DH1[Data Hypervisor 1]
                DH1NICA[DH1 NIC A]
                DH1NICB[DH1 NIC B]
                DH1NICC[DH1 NIC C]
                DH1NICD[DH1 NIC D]
            end
        end
        subgraph VLAN99Data [MGMT VLAN 99]
            subgraph DH2[Data Hypervisor 2]
                DH2NICA[DH2 NIC A]
                DH2NICB[DH2 NIC B]
                DH2NICC[DH2 NIC C]
                DH2NICD[DH2 NIC D]
            end
        end
    end
    
    MH1NICC ---|"10G"| CS
    MH2NICC ---|"10G"| CS
    MS ---|"1G"| MH1NICA
    MS ---|"1G"| MH1NICB
    MS ---|"1G"| MH2NICA
    MS ---|"1G"| MH2NICB
    MS ---|"1G"| DH1NICA
    MS ---|"1G"| DH1NICB
    MS ---|"1G"| DH2NICA
    MS ---|"1G"| DH2NICB

    subgraph VFIOInfrastructure [VFIO Infrastructure]
        subgraph VLAN30 [VFIO VLAN 30]
            VS{VFIO Switch}
            subgraph VH1[VFIO Hypervisor 1]
                VH1NICA[VH1 NIC A]
                VH1NICC[VH1 NIC C]
                VH1NICD[VH1 NIC D]
            end
            subgraph VH2[VFIO Hypervisor 2]
                VH2NICA[VH2 NIC A]
                VH2NICC[VH2 NIC C]
                VH2NICD[VH2 NIC D]
            end
        end
    end
    
    subgraph TestInfrastructure [Test Infrastructure]
        subgraph HybridNetwork [Hybrid VLAN 10 / DMZ Subnet]
            TS{Test Switch}
            subgraph TH[Test Hypervisor]
                THNICA[TH NIC A]
                THNICB[TH NIC B]
            end
            TM[Test PC]
        end
        TS ---|"2.5G VLAN10"| THNICA
        TS ---|"2.5G DMZ"| THNICB
        TS ---|"2.5G"| TM
    end
    
    subgraph VLAN99 [Mgmt VLAN 99]
        MS
        AP
        MH1NICB
        MH2NICB
        QDD
        QDM((QDev Meta))
    end
    
    subgraph Guest [Guest / Wi-Fi DMZ]
        ISPR
        GD[Guest Device 1]
    end

    ISPR ---|"1G"| GD
    MS ---|"1G"| QDM
    TS ---|"1G"| ISPR

    %% Detailed connections
    CS ---|"10G"| DH1NICC
    DH1NICD ---|"25G VLAN99"| DH2NICD
    VS ---|"10G"| VH1NICC
    VS ---|"10G"| VH2NICC
    VH1NICD ---|"25G VLAN99"| VH2NICD
    MS ---|"1G"| VH1NICA
    MS ---|"1G"| VH2NICA
    
    classDef vlan20 fill:#ffd700,stroke:#333,stroke-width:2px;
    class VLAN20 vlan20;
    classDef vlan99 fill:#e0b0ff,stroke:#333,stroke-width:2px;
    class VLAN99,VLAN99Data vlan99;
    classDef vlan30 fill:#90EE90,stroke:#333,stroke-width:2px;
    class VLAN30 vlan30;
    classDef hybridtestnet fill:#ffa500,stroke:#333,stroke-width:2px;
    class HybridNetwork hybridtestnet;
    classDef hypervisor fill:#ffe6cc,stroke:#333,stroke-width:2px;
    class MH1,MH2,DH1,DH2,VH1,VH2,TH hypervisor;
    classDef optional stroke-dasharray: 5 5;
    classDef dmz fill:#ff0000,stroke:#333,stroke-width:2px;
    class Guest dmz;
    classDef infrastructure fill:#e6e6fa,stroke:#333,stroke-width:2px;
    class MetaInfrastructure,DataInfrastructure,VFIOInfrastructure,TestInfrastructure infrastructure;
```
