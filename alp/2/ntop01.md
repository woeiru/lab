```mermaid
graph TD
    INT[Internet] --- |WAN| ISPRWAN[ISP Router WAN]
    
    subgraph GuestZone [Guest / Wi-Fi DMZ]
        subgraph ISPR [ISP Router]
            ISPRWAN[WAN NIC]
            ISPRNIC1[NIC 1]
            ISPRNIC2[NIC 2]
            ISPRNIC3[NIC 3]
            ISPRNIC4[NIC 4]
            ISPRNIC5[NIC 5]
            ISPRWIFI[WiFi NIC]
        end
        GD[Guest Device 1]
    end
    
    ISPRNIC1 ---|"2.5G"| CS{Core Switch}
    ISPRNIC2 ---|"1G"| GD
    ISPRNIC3 -.-|"1G optional"| TS
    ISPRWIFI ---|"WiFi"| APNICW
    CS ---|"10G"| MS{Mgmt Switch}
    CS ---|"10G"| VS{VFIO Switch}
    CS ---|"10G"| TS{Test Switch}
    
    subgraph MetaInfrastructure [Meta Infrastructure]
        CS
        subgraph MH1[Meta Hypervisor 1]
            MH1NICA[NIC A]
            MH1NICB[NIC B]
            MH1NICC[NIC C]
            MH1NICD[NIC D]
        end
        subgraph MH2[Meta Hypervisor 2]
            MH2NICA[NIC A]
            MH2NICB[NIC B]
            MH2NICC[NIC C]
            MH2NICD[NIC D]
        end
        VBA[[Virtual Bridge A]]
        VBB[[Virtual Bridge B]]
        OPN((OpenSense VM))
        QDD((QDev Data))
        QDV((QDev VFIO))
        
        VBA --- MH1NICB
        VBA --- MH2NICB
        VBA --- MH1NICA
        VBA --- MH2NICA
        VBA --- QDD
        VBA --- QDV
        VBB --- OPN
        VBB --- MH1NICC
        VBB --- MH2NICC
        VBB --- MH1NICD
        VBB --- MH2NICD
    end
    
    subgraph DataInfrastructure [Data Infrastructure]
        subgraph VLAN20 [DATA VLAN 20]
            subgraph DH1[Data Hypervisor 1]
                DH1NICA[NIC A]
                DH1NICB[NIC B]
                DH1NICC[NIC C]
                DH1NICD[NIC D]
            end
        end
        subgraph VLAN99Data [MGMT VLAN 99]
            subgraph DH2[Data Hypervisor 2]
                DH2NICA[NIC A]
                DH2NICB[NIC B]
                DH2NICC[NIC C]
                DH2NICD[NIC D]
            end
        end
    end
    
    subgraph ManagementInfrastructure [Management Infrastructure]
        subgraph VLAN99 [Mgmt VLAN 99]
            MS
            MH1NICB
            MH2NICB
        end
        subgraph AP[Admin PC]
            APNICA[NIC A]
            APNICW[NIC W]
            QDM((QDev Meta<br>Container))
        end
    end
    
    MH1NICC ---|"10G"| CS
    MH1NICD ---|"10G"| CS
    MH2NICC -.-|"10G Optional"| CS
    MH2NICD -.-|"10G Optional"| CS
    MS ---|"1G LACP"| MH1NICA
    MS ---|"1G LACP"| MH1NICB
    MS ---|"1G LACP"| MH2NICA
    MS ---|"1G LACP"| MH2NICB
    MS ---|"1G LACP"| DH1NICA
    MS ---|"1G LACP"| DH1NICB
    MS ---|"1G LACP"| DH2NICA
    MS ---|"1G LACP"| DH2NICB
    APNICA ---|"10G"| MS
    QDM -.->|"Container Network"| APNICA

    subgraph VFIOInfrastructure [VFIO Infrastructure]
        subgraph VLAN30 [VFIO VLAN 30]
            VS
            subgraph VH1[VFIO Hypervisor 1]
                VH1NICC[NIC C]
                VH1NICD[NIC D]
            end
            subgraph VH2[VFIO Hypervisor 2]
                VH2NICC[NIC C]
                VH2NICD[NIC D]
            end
        end
    end
    
    subgraph TestInfrastructure [Test Infrastructure]
        subgraph HybridNetwork [Hybrid VLAN 10 / DMZ Subnet]
            TS
            subgraph TM1[Test Machine 1]
                THNICA[NIC A]
                THNICB[NIC B]
                THNICC[NIC C]
                THNICD[NIC D]
            end
            subgraph TM2[Test Machine 2]
                TMNICA[NIC A]
                TMNICC[NIC C]
                TMNICD[NIC D]
            end
            TAP{2.5G AP}
            subgraph TT[Test Tablet]
                TTNICW[NIC W]
            end
        end
        TS ---|"2.5G VLAN99"| THNICA
        TS ---|"2.5G DMZ"| THNICB
        TS ---|"10G VLAN10"| THNICC
        TS ---|"1G DMZ"| TMNICA
        TS ---|"10->2.5G VLAN10"| TMNICC
        THNICD ---|"10G Direct"| TMNICD
        TS ---|"2.5G"| TAP
        TTNICW -.-|"WiFi"| TAP
    end

    %% Detailed connections
    CS ---|"10G"| DH1NICC
    DH1NICD ---|"25G VLAN99"| DH2NICD
    VS ---|"10G"| VH1NICC
    VS ---|"10G"| VH2NICC
    VH1NICD ---|"25G VLAN99"| VH2NICD
    
    classDef physicalDevices fill:#d3d3d3,stroke:#333,stroke-width:2px,fontcolor:#000000;
    class MH1,MH2,DH1,DH2,VH1,VH2,TM1,AP,TM2,TT,ISPR physicalDevices;

    classDef networkDevices fill:#a9a9a9,stroke:#333,stroke-width:2px,fontcolor:#000000;
    class CS,MS,VS,TS,TAP networkDevices;

    classDef virtualDevices fill:#e6e6e6,stroke:#333,stroke-width:2px,fontcolor:#000000;
    class VBA,VBB virtualDevices;

    classDef vlanDataNetwork fill:#ffd700,stroke:#333,stroke-width:2px,fontcolor:#000000;
    class VLAN20 vlanDataNetwork;

    classDef vlanManagement fill:#4169E1,stroke:#333,stroke-width:2px,fontcolor:#000000;
    class VLAN99,VLAN99Data vlanManagement;

    classDef vlanVFIO fill:#90EE90,stroke:#333,stroke-width:2px,fontcolor:#000000;
    class VLAN30 vlanVFIO;

    classDef vlanHybridTest fill:#ffa500,stroke:#333,stroke-width:2px,fontcolor:#000000;
    class HybridNetwork vlanHybridTest;

    classDef optionalConnections stroke-dasharray: 5 5;
    class TTNICW,MH2NICC,MH2NICD optionalConnections;

    classDef securityZone fill:#ff0000,stroke:#333,stroke-width:2px,fontcolor:#000000;
    class GuestZone securityZone;

    classDef infrastructureGroup fill:none,stroke:#800080,stroke-width:4px;
    class MetaInfrastructure,DataInfrastructure,VFIOInfrastructure,TestInfrastructure,ManagementInfrastructure infrastructureGroup;

    classDef virtualServices fill:none,stroke:#0000FF,stroke-width:2px,fontcolor:#000000;
    class QDD,QDV,QDM,OPN virtualServices;

    classDef virtualBridges fill:none,stroke:#808080,stroke-width:2px;
    class VBA,VBB virtualBridges;
```
