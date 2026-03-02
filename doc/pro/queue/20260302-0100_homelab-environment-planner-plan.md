# Homelab MCP Server -- utl/inv Module Design

- Status: queue
- Owner: es
- Started: n/a
- Updated: 2026-03-02
- Links: utl/README.md, cfg/env/site1, doc/arc/00-architecture-overview.md

## Triage Decision

Queued for implementation. The original plan offered three LLM integration
tiers (context paste, CLI pipe, MCP server). Design refresh dropped the first
two and went all-in on MCP as the sole delivery mechanism. This is the right
call: Node.js v20 and npx are already on the system, the MCP TypeScript SDK
is mature, and OpenCode natively supports local MCP servers via STDIO. The
data model and JSON dataset are prerequisites regardless of delivery tier, so
starting with MCP loses nothing and avoids building throwaway intermediate
scripts. Phase 1 is self-contained (types, dataset, resource handlers, server
scaffold) with a clear done-gate: OpenCode can connect and read inventory
resources.

## Goal

Build a local MCP server (`utl/inv/`) that exposes a structured homelab
inventory as live context to AI coding assistants (OpenCode, Claude Desktop,
etc.) via the Model Context Protocol. The LLM gets on-demand access to
infrastructure data -- hosts, VMs, containers, GPUs, storage, networking,
services -- and can query, analyze, diagram, and advise on the homelab without
manual copy-paste of context.

## Problem

Planning homelab infrastructure currently lives in people's heads, scattered
spreadsheets, or ad-hoc notes. When working with an LLM assistant, the user
must manually describe their setup every session. There is no structured,
versionable dataset that captures the full picture (hardware, topology,
allocations, services) in a way that is both human-editable and
machine-readable. Without that foundation, you cannot:

- Give an LLM persistent, accurate awareness of your infrastructure
- Ask questions like "where should I place this new VM?" with real data
- Auto-generate topology or resource-allocation diagrams on demand
- Detect over-provisioning, gaps, or optimization opportunities
- Compare planned vs. current state

MCP solves the "context delivery" problem: instead of the user pasting a
snapshot, the LLM pulls live data through standardized tool calls and resource
reads whenever it needs infrastructure context.

## Why MCP (and why now)

**MCP is the right abstraction for this problem.** The homelab inventory is
a read-mostly dataset that an LLM needs to reference during conversations. MCP
provides exactly three primitives that map cleanly:

| MCP Primitive | Homelab Use                                              |
|---------------|----------------------------------------------------------|
| **Resources** | Expose the inventory data itself -- the LLM reads it     |
| **Tools**     | Query, filter, validate, diagram -- the LLM acts on it   |
| **Prompts**   | Pre-built analysis workflows -- the user triggers them    |

**Why not a simpler approach (context paste, API pipe)?** Those work for
one-shot questions but fail for iterative workflows. With MCP, the LLM can
pull exactly the data slice it needs mid-conversation, call a validation tool
after suggesting a change, and generate a diagram to visualize the result --
all without the user manually orchestrating each step.

**Runtime availability:** Node.js v20 and npx are already installed on the
system. The MCP TypeScript SDK (`@modelcontextprotocol/sdk`) is the ecosystem
standard and provides the most mature implementation. No new runtime
dependencies.

## Architecture

### System context

```
┌─────────────────────────────────────────────────────┐
│  MCP Host (OpenCode / Claude Desktop)               │
│                                                     │
│  ┌───────────┐                                      │
│  │ MCP Client│◄──── STDIO ────► MCP Server          │
│  └───────────┘                  (utl/inv/server)    │
│                                      │              │
└──────────────────────────────────────┼──────────────┘
                                       │
                          ┌────────────┼────────────┐
                          │            ▼            │
                          │   utl/inv/data/*.json   │
                          │   (inventory datasets)  │
                          │                         │
                          │   cfg/env/site1          │
                          │   (live env config)      │
                          └─────────────────────────┘
```

### Transport: STDIO (local)

The server runs as a local process launched by the MCP host via STDIO
transport. This is the standard pattern for local MCP servers:

- Zero network overhead, no port management, no auth needed
- OpenCode launches it automatically via `opencode.json` config
- Claude Desktop uses the same pattern via `claude_desktop_config.json`
- One server instance per MCP host session

### Runtime: TypeScript on Node.js

| Factor               | Decision        | Rationale                                  |
|----------------------|-----------------|--------------------------------------------|
| Language             | TypeScript      | MCP SDK ecosystem standard                 |
| Runtime              | Node.js v20     | Already installed on system                |
| Package manager      | npm/npx         | Already available (npx 9.2.0)              |
| MCP SDK              | `@modelcontextprotocol/sdk` | Official reference implementation |
| JSON processing      | Native + `jq`   | JS handles JSON natively; `jq` for CLI     |

The TypeScript code lives in `utl/inv/src/` and compiles to `utl/inv/dist/`.
A wrapper script `utl/inv/server` handles startup for both direct invocation
and MCP host launch.

### Data layer: JSON inventory (unchanged from original plan)

The JSON dataset concept from the original plan is preserved -- it is the
prerequisite for everything the MCP server exposes. One file per environment
(`utl/inv/data/<env>.json`), `jq`-queryable, git-diffable.

## Data Model

### Entity hierarchy

```
site
  └── network (vlans, subnets, gateways)
  └── host (physical machines)
        ├── gpu (PCI devices)
        ├── storage (disks, pools, datasets, mounts)
        ├── vm (virtual machines)
        │     └── service
        └── container (LXC)
              └── service
```

### JSON schema (abbreviated)

```json
{
  "schema_version": "1.0",
  "environment": "site1",
  "description": "Production homelab",
  "updated": "2026-03-02",

  "network": {
    "subnets": [
      {
        "name": "lan",
        "cidr": "192.168.178.0/24",
        "gateway": "192.168.178.1",
        "vlan": null,
        "description": "Main LAN"
      }
    ],
    "dns": {
      "nameserver": "192.168.178.1",
      "searchdomain": "lan.local"
    }
  },

  "hosts": [
    {
      "id": "h1",
      "role": "hypervisor",
      "description": "Primary Proxmox node",
      "hardware": {
        "cpu": { "model": "Xeon W-2175", "cores": 28, "sockets": 1 },
        "memory_gb": 128,
        "nics": [
          { "name": "enp0s31f6", "ip": "192.168.178.110", "subnet": "lan" }
        ]
      },
      "gpus": [
        {
          "id": "gpu0",
          "model": "NVIDIA RTX 3090",
          "pci": "0000:3b:00.0",
          "driver": "nvidia",
          "passthrough_to": "vm:211"
        }
      ],
      "storage": [
        {
          "id": "btrfs-sto",
          "type": "btrfs",
          "devices": ["nvme0n1", "nvme2n1"],
          "raid": "raid1",
          "mountpoint": "/sto"
        }
      ],
      "vms": [
        {
          "id": 211,
          "name": "fedora-vm",
          "cores": 8,
          "memory_gb": 8,
          "disk_gb": 64,
          "gpu_passthrough": "gpu0",
          "services": []
        }
      ],
      "containers": [
        {
          "id": 111,
          "hostname": "pbs1",
          "role": "backup",
          "ip": "192.168.178.111",
          "cores": 4,
          "memory_gb": 8,
          "services": [
            { "name": "proxmox-backup-server", "type": "backup", "port": 8007 }
          ]
        }
      ]
    }
  ]
}
```

### Design notes on the schema

- **Flat-ish hierarchy**: hosts own VMs, containers, GPUs, and storage
  directly. No deeply nested ownership chains. Maps naturally to both JSON
  traversal and MCP resource URIs.
- **String cross-references**: GPU passthrough uses `"passthrough_to": "vm:211"`
  style references. Keeps things denormalized and queryable.
- **Extensible**: adding a new entity type (e.g., `switches`, `ups`) means
  adding a new array. No schema migration needed.

## MCP Server Design

### Capabilities declared

```json
{
  "capabilities": {
    "resources": { "listChanged": false },
    "tools": { "listChanged": false },
    "prompts": { "listChanged": false }
  }
}
```

All three MCP primitives are supported. `listChanged` is false initially (the
server's capabilities are static per session). This can be upgraded later if
we want hot-reload of inventory data.

---

### Resources (data the LLM reads)

Resources expose the inventory as structured context that the LLM can pull on
demand. Each resource has a URI, MIME type, and text/binary content.

#### Static resources

| URI                              | Name                  | Description                                            | MIME type          |
|----------------------------------|-----------------------|--------------------------------------------------------|--------------------|
| `homelab://site1/inventory`      | Full inventory        | Complete JSON dataset for the environment              | `application/json` |
| `homelab://site1/summary`        | Infrastructure summary| Compact Markdown overview (hosts, totals, allocations) | `text/markdown`    |
| `homelab://site1/network`        | Network topology      | Subnets, DNS, IP assignments as structured text        | `text/markdown`    |

#### Resource templates (parameterized)

| URI Template                              | Name             | Description                                     |
|-------------------------------------------|------------------|-------------------------------------------------|
| `homelab://{env}/inventory`               | Inventory        | Full dataset for any environment                |
| `homelab://{env}/summary`                 | Summary          | Overview for any environment                    |
| `homelab://{env}/host/{hostId}`           | Host detail      | Single host with all VMs/CTs/GPUs/storage       |
| `homelab://{env}/host/{hostId}/vms`       | VMs on host      | All VMs on a specific host                      |
| `homelab://{env}/host/{hostId}/containers`| Containers       | All containers on a specific host               |
| `homelab://{env}/host/{hostId}/storage`   | Storage          | Storage configuration for a host                |
| `homelab://{env}/host/{hostId}/gpus`      | GPUs             | GPU devices and passthrough status              |
| `homelab://{env}/network`                 | Network          | Network topology for an environment             |
| `homelab://{env}/services`                | Services         | All services across all hosts                   |

**Why these resource boundaries:** Each template maps to a natural question
scope. The LLM reads `homelab://site1/summary` for broad context, then drills
into `homelab://site1/host/h1/gpus` when discussing GPU passthrough. This
keeps token usage efficient -- the LLM fetches only what it needs.

**Content format:** Resources return either raw JSON (for the full inventory)
or pre-rendered Markdown (for summaries and detail views). The Markdown format
is optimized for LLM consumption with tables, key-value pairs, and
cross-reference annotations.

---

### Tools (actions the LLM performs)

Tools are model-controlled: the LLM decides when to call them based on the
user's question. Each tool has a JSON Schema for input validation and returns
structured content.

#### Query tools

| Tool name              | Description                                          | Key parameters                       |
|------------------------|------------------------------------------------------|--------------------------------------|
| `inv_search`           | Search entities by type, name, role, IP, or property | `env`, `entity_type`, `query`        |
| `inv_resource_usage`   | Calculate resource utilization per host or total     | `env`, `scope` (host/total)          |
| `inv_list_services`    | List all services with host/CT/VM location and ports | `env`, `filter` (type, port, host)   |
| `inv_find_by_ip`       | Resolve an IP address to its host/VM/CT              | `env`, `ip`                          |
| `inv_dependency_map`   | Show relationships (GPU->VM, mount->CT, etc.)        | `env`, `entity_id`                   |

#### Analysis tools

| Tool name              | Description                                          | Key parameters                       |
|------------------------|------------------------------------------------------|--------------------------------------|
| `inv_capacity`         | Show free vs. allocated resources per host           | `env`, `resource` (cpu/ram/gpu/disk) |
| `inv_suggest_placement`| Recommend which host to place a new VM/CT on         | `env`, `cores`, `memory_gb`, `needs_gpu` |
| `inv_validate`         | Check dataset for errors (dupes, bad refs, gaps)     | `env`                                |
| `inv_compare_hosts`    | Side-by-side comparison of two hosts                 | `env`, `host_a`, `host_b`           |

#### Generation tools

| Tool name              | Description                                          | Key parameters                       |
|------------------------|------------------------------------------------------|--------------------------------------|
| `inv_diagram`          | Generate Mermaid diagram code                        | `env`, `view` (network/deploy/resource) |
| `inv_export_context`   | Export full LLM context document (legacy paste flow) | `env`, `format` (markdown/compact)   |

#### Tool design principles

- **Read-only**: No tool modifies the inventory dataset. The dataset is
  edited by the user (directly or via a future CLI). The MCP server is a
  query/analysis layer, not a write API. This is a deliberate safety choice
  for infrastructure data.
- **Structured output**: Tools return both `content` (text for the LLM) and
  `structuredContent` (JSON for programmatic use) where applicable.
- **Error semantics**: Tools return `isError: true` with descriptive messages
  for invalid environments, missing entities, or malformed queries. No
  silent failures.

#### Detailed tool specifications

##### `inv_search`

```json
{
  "name": "inv_search",
  "title": "Search Infrastructure",
  "description": "Search homelab entities by type, name, role, IP address, or any property value. Returns matching entities with their location in the hierarchy.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "env": {
        "type": "string",
        "description": "Environment name (e.g., 'site1')"
      },
      "entity_type": {
        "type": "string",
        "enum": ["host", "vm", "container", "gpu", "storage", "service", "subnet"],
        "description": "Type of entity to search"
      },
      "query": {
        "type": "string",
        "description": "Search term -- matches against name, id, role, IP, model, or any string property"
      }
    },
    "required": ["env", "query"]
  }
}
```

##### `inv_capacity`

```json
{
  "name": "inv_capacity",
  "title": "Resource Capacity",
  "description": "Calculate free vs. allocated resources. Shows total capacity, current allocation, and remaining headroom for CPU cores, RAM, GPU devices, and disk space.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "env": {
        "type": "string",
        "description": "Environment name"
      },
      "resource": {
        "type": "string",
        "enum": ["cpu", "ram", "gpu", "disk", "all"],
        "description": "Resource type to analyze (default: all)"
      },
      "host": {
        "type": "string",
        "description": "Specific host ID to scope analysis (omit for cluster-wide)"
      }
    },
    "required": ["env"]
  }
}
```

##### `inv_suggest_placement`

```json
{
  "name": "inv_suggest_placement",
  "title": "Suggest VM/CT Placement",
  "description": "Recommend the best host for a new VM or container based on available resources, current load distribution, and optional GPU requirement.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "env": {
        "type": "string",
        "description": "Environment name"
      },
      "cores": {
        "type": "number",
        "description": "Required CPU cores"
      },
      "memory_gb": {
        "type": "number",
        "description": "Required RAM in GB"
      },
      "disk_gb": {
        "type": "number",
        "description": "Required disk in GB"
      },
      "needs_gpu": {
        "type": "boolean",
        "description": "Whether a GPU is required"
      },
      "prefer_host": {
        "type": "string",
        "description": "Preferred host ID (soft preference, not hard constraint)"
      }
    },
    "required": ["env", "cores", "memory_gb"]
  }
}
```

##### `inv_diagram`

```json
{
  "name": "inv_diagram",
  "title": "Generate Mermaid Diagram",
  "description": "Generate Mermaid diagram code for visualizing the homelab infrastructure. Supports network topology, deployment/architecture, and resource allocation views.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "env": {
        "type": "string",
        "description": "Environment name"
      },
      "view": {
        "type": "string",
        "enum": ["network", "deploy", "resource"],
        "description": "Diagram type: 'network' (topology), 'deploy' (hosts->VMs->services), 'resource' (CPU/RAM allocation)"
      },
      "host": {
        "type": "string",
        "description": "Scope to a specific host (omit for full environment)"
      }
    },
    "required": ["env", "view"]
  }
}
```

##### `inv_validate`

```json
{
  "name": "inv_validate",
  "title": "Validate Inventory",
  "description": "Check the inventory dataset for structural errors: duplicate IDs, broken cross-references, impossible resource allocations (overcommit), missing required fields, and IP conflicts.",
  "inputSchema": {
    "type": "object",
    "properties": {
      "env": {
        "type": "string",
        "description": "Environment name to validate"
      }
    },
    "required": ["env"]
  }
}
```

---

### Prompts (user-triggered workflows)

Prompts are user-controlled: they appear as slash commands or selectable
templates in the MCP host UI. Each prompt injects a structured message
sequence that guides the LLM through a specific analysis workflow.

| Prompt name               | Description                                            | Arguments             |
|---------------------------|--------------------------------------------------------|-----------------------|
| `infrastructure_review`   | Full infrastructure health check and recommendations   | `env`                 |
| `capacity_planning`       | Analyze headroom and plan for new workloads             | `env`, `new_workload` |
| `migration_plan`          | Plan moving a VM/CT between hosts with impact analysis  | `env`, `entity_id`, `target_host` |
| `gpu_passthrough_review`  | Review GPU allocation and passthrough configuration     | `env`                 |
| `storage_audit`           | Analyze storage layout, redundancy, and capacity        | `env`                 |
| `network_overview`        | Review network topology, IP allocation, and gaps        | `env`                 |

#### Prompt detail: `infrastructure_review`

```json
{
  "name": "infrastructure_review",
  "title": "Infrastructure Review",
  "description": "Comprehensive health check of the homelab. Reviews resource utilization, identifies imbalances, checks for single points of failure, and provides actionable recommendations.",
  "arguments": [
    {
      "name": "env",
      "description": "Environment to review (e.g., 'site1')",
      "required": true
    }
  ]
}
```

When triggered, the server returns a message sequence that:

1. Reads the full inventory via `homelab://{env}/inventory` (embedded resource)
2. Includes a system-level analysis prompt with specific review criteria:
   - Resource utilization balance across hosts
   - Single points of failure (services on only one host)
   - GPU passthrough correctness
   - Storage redundancy assessment
   - Network IP gap detection
   - Over/under-provisioning warnings
3. Asks the LLM to produce a structured report with severity ratings

#### Prompt detail: `capacity_planning`

```json
{
  "name": "capacity_planning",
  "title": "Capacity Planning",
  "description": "Analyze current resource usage and plan for adding new workloads. Shows what fits where and what would require hardware changes.",
  "arguments": [
    {
      "name": "env",
      "description": "Environment to analyze",
      "required": true
    },
    {
      "name": "new_workload",
      "description": "Description of planned workload (e.g., 'Kubernetes cluster, 3 nodes, 4 cores each, 16GB RAM')",
      "required": false
    }
  ]
}
```

#### Prompt detail: `migration_plan`

```json
{
  "name": "migration_plan",
  "title": "Migration Plan",
  "description": "Plan the migration of a VM or container to a different host. Analyzes resource fit, storage requirements, GPU dependencies, network changes, and service impact.",
  "arguments": [
    {
      "name": "env",
      "description": "Environment name",
      "required": true
    },
    {
      "name": "entity_id",
      "description": "ID of the VM or container to migrate (e.g., '211' or 'pbs1')",
      "required": true
    },
    {
      "name": "target_host",
      "description": "Target host ID (e.g., 'w2'). Omit for automatic suggestion.",
      "required": false
    }
  ]
}
```

---

## Module Structure

```
utl/inv/
├── README.md               Documentation and usage examples
├── package.json             Node.js package (MCP SDK dependency)
├── tsconfig.json            TypeScript configuration
├── server                   Bash wrapper: entry point for MCP hosts
├── src/
│   ├── index.ts             MCP server setup, capability declaration
│   ├── resources.ts         Resource handlers (list, read, templates)
│   ├── tools.ts             Tool handlers (search, capacity, diagram, etc.)
│   ├── prompts.ts           Prompt handlers (review, planning, migration)
│   ├── inventory.ts         Dataset loading, caching, query helpers
│   ├── diagram.ts           Mermaid generation logic
│   ├── summary.ts           Markdown summary/context generation
│   └── types.ts             TypeScript type definitions for the schema
├── dist/                    Compiled JavaScript (gitignored)
├── data/
│   ├── site1.json           Environment dataset (source of truth)
│   └── .gitkeep
├── config/
│   └── settings.json        Server config (default env, data paths)
└── test/
    ├── server.test.ts       MCP protocol integration tests
    ├── inventory.test.ts    Dataset loading and query tests
    ├── tools.test.ts        Tool handler unit tests
    └── fixtures/
        └── test-env.json    Test dataset
```

### Entry point: `utl/inv/server`

```bash
#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Build if needed (dev convenience)
if [[ ! -d "${DIR}/dist" ]] || [[ "${1:-}" == "--build" ]]; then
    npm --prefix "${DIR}" run build
fi

# Launch MCP server via STDIO
exec node "${DIR}/dist/index.js" "$@"
```

This wrapper handles the gap between bash-native tooling patterns and the
TypeScript MCP server. It is what OpenCode and Claude Desktop invoke.

### `package.json` dependencies

```json
{
  "name": "@lab/inv-mcp-server",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "tsc --watch"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0"
  },
  "devDependencies": {
    "typescript": "^5.4.0",
    "@types/node": "^20.0.0"
  }
}
```

Minimal dependency footprint: just the MCP SDK and TypeScript. No Express, no
framework -- the SDK handles STDIO transport natively.

---

## OpenCode Integration

### Configuration

Add to `~/.config/opencode/opencode.json` (or project `opencode.json`):

```json
{
  "mcp": {
    "homelab": {
      "type": "local",
      "command": ["bash", "/home/es/lab/utl/inv/server"],
      "enabled": true,
      "environment": {
        "INV_DEFAULT_ENV": "site1",
        "INV_DATA_DIR": "/home/es/lab/utl/inv/data"
      }
    }
  }
}
```

### Usage patterns in OpenCode

Once configured, the homelab MCP server is available in every OpenCode
session. Example interactions:

**Automatic context pull (resource read):**
```
> What's my current GPU setup?

The LLM reads homelab://site1/host/h1/gpus and responds with GPU details,
passthrough status, and driver info without the user having to describe
their setup.
```

**Tool invocation (model-controlled):**
```
> I want to add a new container with 4 cores and 16GB RAM for a
  Jellyfin media server. Where should I put it?

The LLM calls inv_suggest_placement and inv_capacity to analyze both
hosts, then recommends placement with reasoning.
```

**Prompt workflow (user-triggered):**
```
> /infrastructure_review site1

Triggers the infrastructure_review prompt. The LLM receives the full
inventory as context plus structured analysis instructions, and produces
a comprehensive health report.
```

**Diagram generation:**
```
> Show me my network topology as a diagram

The LLM calls inv_diagram with view=network and returns Mermaid code
that can be rendered in the terminal or exported.
```

### Claude Desktop integration

Same server, different config location (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "homelab": {
      "command": "bash",
      "args": ["/home/es/lab/utl/inv/server"],
      "env": {
        "INV_DEFAULT_ENV": "site1",
        "INV_DATA_DIR": "/home/es/lab/utl/inv/data"
      }
    }
  }
}
```

---

## Implementation Phases

### Phase 1 -- Data foundation + minimal server

| Deliverable                | Effort | Notes                                 |
|----------------------------|--------|---------------------------------------|
| JSON schema types (`types.ts`) | Small  | TypeScript interfaces for the schema |
| Sample dataset (`data/site1.json`) | Small  | Populated from `cfg/env/site1`   |
| Inventory loader (`inventory.ts`) | Small  | Read, parse, cache, basic queries |
| MCP server scaffold (`index.ts`) | Small  | SDK setup, STDIO transport, caps  |
| Summary resource (`summary.ts`) | Medium | Markdown context generation       |
| Core resources (inventory, summary, host detail) | Medium | Resource handlers |
| `package.json` + `tsconfig.json` + `server` wrapper | Small | Build infra |

**Done when:** `utl/inv/server` starts, connects via STDIO, and the LLM can
read `homelab://site1/inventory` and `homelab://site1/summary`.

### Phase 2 -- Query and analysis tools

| Deliverable                | Effort | Notes                                 |
|----------------------------|--------|---------------------------------------|
| `inv_search`               | Medium | Full-text search across entities      |
| `inv_capacity`             | Medium | Resource utilization calculations     |
| `inv_suggest_placement`    | Medium | Placement algorithm with scoring      |
| `inv_validate`             | Medium | Structural checks, cross-ref validation|
| `inv_find_by_ip`           | Small  | IP -> entity resolution               |
| `inv_list_services`        | Small  | Service aggregation with filters      |
| `inv_compare_hosts`        | Small  | Side-by-side host comparison          |
| `inv_dependency_map`       | Small  | Relationship traversal                |

**Done when:** The LLM can answer "where should I put a new VM?" with
data-backed recommendations.

### Phase 3 -- Diagrams and visualization

| Deliverable                | Effort | Notes                                 |
|----------------------------|--------|---------------------------------------|
| `inv_diagram` tool         | Medium | Mermaid code generation               |
| Network topology view      | Medium | Nodes, connections, subnets, IPs      |
| Deployment view            | Medium | Hosts -> VMs -> services hierarchy    |
| Resource allocation view   | Medium | CPU/RAM/GPU distribution              |

**Done when:** The LLM can generate correct Mermaid diagrams on demand.

### Phase 4 -- Prompts and workflows

| Deliverable                | Effort | Notes                                 |
|----------------------------|--------|---------------------------------------|
| `infrastructure_review`    | Medium | Full health check prompt              |
| `capacity_planning`        | Medium | Headroom analysis prompt              |
| `migration_plan`           | Medium | Move planning with impact analysis    |
| `gpu_passthrough_review`   | Small  | GPU-specific review prompt            |
| `storage_audit`            | Small  | Storage layout review prompt          |
| `network_overview`         | Small  | Network topology review prompt        |

**Done when:** Users can trigger `/infrastructure_review site1` and get a
structured, actionable report.

### Phase 5 -- Polish and extensions

| Deliverable                | Effort | Notes                                 |
|----------------------------|--------|---------------------------------------|
| `inv_export_context` tool  | Small  | Legacy context-paste flow             |
| `cfg/env/` sync script     | Medium | Import from live env config to JSON   |
| Multi-environment support  | Small  | Compare across site1, site2, etc.     |
| Test suite                 | Medium | MCP protocol + unit tests             |
| README + OpenCode config   | Small  | Setup documentation                   |

**Done when:** The module is documented, tested, and handles multiple
environments.

---

## Dataset Population Strategy

The initial `data/site1.json` is populated from `cfg/env/site1` which
contains all the real infrastructure data:

| cfg/env/site1 variable         | JSON target                          |
|--------------------------------|--------------------------------------|
| `HY_IPS` (h1=.110, w2=.120)   | `hosts[].hardware.nics[].ip`         |
| `CT_IPS` (pbs1=.111, etc.)    | `hosts[].containers[].ip`            |
| GPU PCI addresses per node     | `hosts[].gpus[].pci`                 |
| Container definitions (111-113)| `hosts[].containers[]`               |
| VM 211 config                  | `hosts[].vms[]`                      |
| ZFS/BTRFS storage config       | `hosts[].storage[]`                  |
| NFS/SMB service config         | `containers[].services[]`            |
| Subnet 192.168.178.0/24        | `network.subnets[]`                  |

A one-time `utl/inv/init` script (bash, using `jq`) will read `cfg/env/site1`
and generate the initial JSON. After that, the JSON is the source of truth
and is maintained directly.

---

## Conventions

- The MCP server is TypeScript under `utl/inv/src/`, following standard Node.js
  project patterns (not the bash `lib/ops/` conventions).
- The `server` wrapper script follows `utl/` patterns: extensionless bash,
  `set -euo pipefail`, self-locating via `BASH_SOURCE[0]`.
- JSON datasets in `data/` are tracked in git (versionable infrastructure
  planning is the point).
- `dist/` is gitignored (compiled output).
- `node_modules/` is gitignored.
- No secrets in repo -- environment-specific config via env vars only.
- The `init` script that populates from `cfg/env/` is a bash script using `jq`
  (consistent with existing `utl/` tooling).

## Done Criteria

- `utl/inv/` directory exists with MCP server functional via STDIO.
- OpenCode can connect to it via `opencode.json` config and list
  resources/tools/prompts.
- At least one resource (`homelab://site1/summary`) returns useful context.
- At least one tool (`inv_capacity`) returns correct analysis.
- At least one prompt (`infrastructure_review`) produces a guided review.
- `utl/inv/server` starts cleanly and passes MCP protocol handshake.
- Sample dataset (`data/site1.json`) populated from `cfg/env/site1`.
- All TypeScript compiles. Wrapper script passes `bash -n`.

## Open Questions

1. **Dataset versioning**: Should `data/site1.json` include a `planned` variant
   (e.g., `data/site1-planned.json`) for comparing current vs. desired state?
   Recommendation: yes, with a `inv_compare_plan` tool in Phase 5.

2. **Write tools**: Should Phase 5+ include tools that modify the dataset
   (add a VM, update IP, etc.)? This would let the LLM make changes the user
   confirms. Recommendation: defer -- read-only is safer for infrastructure
   data. Revisit after the read path proves valuable.

3. **Live data integration**: Should the server optionally query live
   infrastructure (PVE API, SSH to hosts) for real-time data alongside the
   static dataset? Recommendation: future scope. The static dataset is
   simpler, safer, and sufficient for planning. A `inv_sync` tool could
   pull live data into the JSON in a later phase.

4. **Resource subscriptions**: Should the server support MCP resource
   subscriptions (notify clients when `data/*.json` changes on disk)?
   Recommendation: nice-to-have for Phase 5. Use `fs.watch` on the data
   directory and emit `notifications/resources/updated`.
