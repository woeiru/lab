<!-- 
    This documentation focuses exclusively on generic pure functions from the lib/ folder.
    Pure functions are stateless, parameterized, and environment-independent.
    They provide predictable behavior and are fully testable with explicit inputs.
    
    The lib/ folder contains three categories of pure functions:
    - lib/core/  : Core system utilities (error handling, logging, timing)
    - lib/ops/   : Operations functions (infrastructure management)
    - lib/gen/   : General utilities (environment, security, infrastructure)
-->

# Pure Functions Reference

Generic pure functions available in the Lab Environment Management System.

## 📚 Library Structure

The `lib/` folder contains three categories of pure functions:

### Core Utilities (`lib/core/`)
- **err**: Error handling and stack traces
- **lo1**: Module-specific debug logging
- **tme**: Performance timing and monitoring
- **ver**: Module version verification

### Operations Functions (`lib/ops/`)
- **aux**: Auxiliary operations and utilities
- **gpu**: GPU passthrough management
- **net**: Network configuration and management
- **pbs**: Proxmox Backup Server operations
- **pve**: Proxmox VE cluster management
- **srv**: System service operations
- **sto**: Storage and filesystem management
- **sys**: System-level operations
- **usr**: User account management

### General Utilities (`lib/gen/`)
- **env**: Environment configuration utilities
- **inf**: Infrastructure deployment utilities
- **sec**: Security and credential management
- **ssh**: SSH key and connection management

## 🔍 Function Metadata Table

<!-- AUTO-GENERATED SECTION: DO NOT EDIT MANUALLY -->
<!-- Command: aux-ffl aux-laf "" "$LIB_CORE_DIR" & aux-ffl aux-laf "" "$LIB_OPS_DIR" & aux-ffl aux-laf "" "$LIB_GEN_DIR" -->

| Library | Module | Function | Description |
|---------|--------|----------|-------------|
<!-- CORE FUNCTIONS -->
| core | /home/es/lab/lib/core/[32merr[0m - Contains [31m377[0m Lines and [33m15[0m Functions |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | | Func    | Arguments        | Shortname          | Description                          | Size | Loc  | file | lib  | src  | |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | | err_pro | Process error    |                    |                                      | 33   | 53   | 2    |      |      | |  |  |
| core | | cess_er | messages and     |                    |                                      |      |      |      |      |      | |  |  |
| core | | ror     | log them         |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | appropriately    |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | err_lo1 | Function to      |                    |                                      | 16   | 88   | 1    |      |      | |  |  |
| core | | _handle | handle errors    |                    |                                      |      |      |      |      |      | |  |  |
| core | | _error  | more             |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | comprehensively  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | clean_e | Function to      |                    |                                      | 6    | 106  | 2    |      | 12   | |  |  |
| core | | xit     | ensure clean     |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | exit from the    |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | script           |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | has_err | Function to      |                    |                                      | 13   | 114  | 1    |      |      | |  |  |
| core | | ors     | check if a       |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | component has    |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | any errors       |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | error_h | Enhanced error   |                    |                                      | 31   | 129  | 3    |      |      | |  |  |
| core | | andler  | handler          |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | function that    |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | only catches     |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | real errors      |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | enable_ | Function to      |                    |                                      | 4    | 162  | 2    |      |      | |  |  |
| core | | error_t | enable error     |                    |                                      |      |      |      |      |      | |  |  |
| core | | rap     | trapping         |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | disable | Function to      |                    |                                      | 4    | 168  | 2    |      |      | |  |  |
| core | | _error_ | disable error    |                    |                                      |      |      |      |      |      | |  |  |
| core | | trap    | trapping         |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | dangero | Wrap dangerous   | Example usage in   |                                      | 6    | 175  |      |      |      | |  |  |
| core | | us_oper | operations with  | your scripts |       |                                      |      |      |      |      |      | |  |
| core | | ation   | error trapping   |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | safe_op | For package      |                    |                                      | 6    | 183  |      |      |      | |  |  |
| core | | eration | management and   |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | other safe       |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | operations,      |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | don't use error  |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | trapping         |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | print_e | Enhanced error   |                    |                                      | 93   | 191  | 1    |      |      | |  |  |
| core | | rror_re | reporting        |                    |                                      |      |      |      |      |      | |  |  |
| core | | port    | function with    |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | better           |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | organization     |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | setup_e | Setup function   |                    |                                      | 12   | 286  | 2    |      |      | |  |  |
| core | | rror_ha | to initialize    |                    |                                      |      |      |      |      |      | |  |  |
| core | | ndling  | error handling   |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | registe | Central trap     |                    |                                      | 11   | 300  | 1    |      |      | |  |  |
| core | | r_clean | registration     |                    |                                      |      |      |      |      |      | |  |  |
| core | | up      | system           |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | main_cl | Main cleanup     |                    |                                      | 20   | 313  | 2    |      |      | |  |  |
| core | | eanup   | orchestrator     |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | main_er | Central error    |                    |                                      | 9    | 335  | 1    |      |      | |  |  |
| core | | ror_han | handler          |                    |                                      |      |      |      |      |      | |  |  |
| core | | dler    |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | init_tr | Initialize trap  |                    |                                      | 13   | 346  | 1    |      |      | |  |  |
| core | | aps     | system           |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | /home/es/lab/lib/core/[32mlo1[0m - Contains [31m412[0m Lines and [33m17[0m Functions |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | | Func    | Arguments        | Shortname          | Description                          | Size | Loc  | file | lib  | src  | |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | | lo1_deb | Enhanced debug   |                    |                                      | 8    | 46   | 20   |      |      | |  |  |
| core | | ug_log  | logging - moved  |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | to top           |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | get_cac | Log state        |                    |                                      | 8    | 87   | 1    |      |      | |  |  |
| core | | hed_log | caching helper   |                    |                                      |      |      |      |      |      | |  |  |
| core | | _state  | functions        |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | dump_st | Update           |                    |                                      | 10   | 97   | 3    |      |      | |  |  |
| core | | ack_tra | dump_stack_trace |                    |                                      |      |      |      |      |      | |  |  |
| core | | ce      |  to use          |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | lo1_debug_log    |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | cleanup | Performance      |                    |                                      | 9    | 109  | 1    |      |      | |  |  |
| core | | _cache  | optimization     |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | ensure_ | Maintenance      |                    |                                      | 15   | 120  | 2    |      |      | |  |  |
| core | | state_d | functions        |                    |                                      |      |      |      |      |      | |  |  |
| core | | irector |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | | ies     |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | init_st |                  |                    |                                      | 4    | 136  | 1    |      |      | |  |  |
| core | | ate_fil |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | | es      |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | is_root | Core functions   |                    |                                      | 7    | 142  | 2    |      |      | |  |  |
| core | | _functi |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | | on      |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | get_bas | Update           |                    |                                      | 44   | 151  | 3    |      |      | |  |  |
| core | | e_depth | get_base_depth   |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | to use           |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | lo1_debug_log    |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | calcula |                  |                    |                                      | 3    | 196  | 1    |      |      | |  |  |
| core | | te_fina |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | | l_depth |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | get_ind |                  |                    |                                      | 17   | 200  | 1    |      |      | |  |  |
| core | | ent     |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | get_col |                  |                    |                                      | 8    | 218  | 1    |      |      | |  |  |
| core | | or      |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | log     | Main logging     |                    |                                      | 36   | 228  | 9    | 29   |      | |  |  |
| core | |         | function         |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | setlog  | Logger control   |                    |                                      | 24   | 266  | 7    |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | init_lo | Update           | Initialization     |                                      | 44   | 293  | 3    |      |      | |  |  |
| core | | gger    | init_logger to   | and cleanup        |                                      |      |      |      |      |      | |  |  |
| core | |         | use              |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | lo1_debug_log    |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | cleanup | Update           |                    |                                      | 8    | 339  | 3    |      |      | |  |  |
| core | | _logger | cleanup_logger   |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | to use           |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | lo1_debug_log    |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | lo1_log | Standard         |                    |                                      | 31   | 354  | 3    |      |      | |  |  |
| core | | _messag | logging          |                    |                                      |      |      |      |      |      | |  |  |
| core | | e       | function for     |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | modules to use   |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | lo1_tme | Logging          |                    |                                      | 15   | 387  | 1    |      |      | |  |  |
| core | | _log_wi | function with    |                    |                                      |      |      |      |      |      | |  |  |
| core | | th_time | timing           |                    |                                      |      |      |      |      |      | |  |  |
| core | | r       | information      |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | /home/es/lab/lib/core/[32mtme[0m - Contains [31m586[0m Lines and [33m15[0m Functions |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | | Func    | Arguments        | Shortname          | Description                          | Size | Loc  | file | lib  | src  | |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | | tme_ini | Initialize       |                    |                                      | 83   | 61   | 2    |      |      | |  |  |
| core | | t_timer | timer system     |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | with optional    |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | log file         |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | tme_sta | Start timing a   |                    |                                      | 32   | 146  | 2    |      |      | |  |  |
| core | | rt_time | component with   |                    |                                      |      |      |      |      |      | |  |  |
| core | | r       | optional parent  |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | component        |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | tme_sto | Stop timing for  |                    |                                      | 5    | 180  | 1    |      |      | |  |  |
| core | | p_timer | a component      |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | (alias for       |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | end_timer for    |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | compatibility)   |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | tme_end | End timing for   |                    |                                      | 30   | 187  | 4    |      |      | |  |  |
| core | | _timer  | a component      |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | calcula | Calculate the    |                    |                                      | 12   | 219  | 1    |      |      | |  |  |
| core | | te_comp | depth of a       |                    |                                      |      |      |      |      |      | |  |  |
| core | | onent_d | component in     |                    |                                      |      |      |      |      |      | |  |  |
| core | | epth    | the timing tree  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | print_t | Print formatted  |                    |                                      | 48   | 233  | 2    |      |      | |  |  |
| core | | iming_e | timing entry     |                    |                                      |      |      |      |      |      | |  |  |
| core | | ntry    |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | sort_co | Helper function  |                    |                                      | 22   | 283  | 3    |      |      | |  |  |
| core | | mponent | to sort an       |                    |                                      |      |      |      |      |      | |  |  |
| core | | s_by_du | array of         |                    |                                      |      |      |      |      |      | |  |  |
| core | | ration  | component names  |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | by their         |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | TME_DURATIONS    |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | print_t | Recursive        |                    |                                      | 47   | 307  | 3    |      |      | |  |  |
| core | | ree_rec | function to      |                    |                                      |      |      |      |      |      | |  |  |
| core | | ursive  | print the        |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | component tree   |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | tme_set | The settme       |                    |                                      | 65   | 356  | 5    |      |      | |  |  |
| core | | tme     | function to      |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | control timer    |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | output           |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | tme_pri | Enhanced timing  |                    |                                      | 41   | 423  | 1    |      |      | |  |  |
| core | | nt_timi | report           |                    |                                      |      |      |      |      |      | |  |  |
| core | | ng_repo |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | | rt      |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | tme_sta | Example of how   |                    |                                      | 4    | 466  | 1    |      |      | |  |  |
| core | | rt_nest | to use nested    |                    |                                      |      |      |      |      |      | |  |  |
| core | | ed_timi | timing           |                    |                                      |      |      |      |      |      | |  |  |
| core | | ng      |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | tme_end |                  |                    |                                      | 4    | 471  | 1    |      |      | |  |  |
| core | | _nested |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | | _timing |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | tme_cle |                  |                    |                                      | 19   | 476  | 1    |      |      | |  |  |
| core | | anup_ti |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | | mer     |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | tme_set | Control nested   |                    |                                      | 44   | 497  | 2    |      |      | |  |  |
| core | | _output | TME terminal     |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | output switches  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | tme_sho | Display current  |                    |                                      | 11   | 543  | 1    |      |      | |  |  |
| core | | w_outpu | TME terminal     |                    |                                      |      |      |      |      |      | |  |  |
| core | | t_setti | output settings  |                    |                                      |      |      |      |      |      | |  |  |
| core | | ngs     |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | /home/es/lab/lib/core/[32mver[0m - Contains [31m399[0m Lines and [33m9[0m Functions |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | | Func    | Arguments        | Shortname          | Description                          | Size | Loc  | file | lib  | src  | |  |  |
| core | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| core | | ver_log | Debug logging    |                    | ------------------------------------ | 20   | 34   | 26   |      |      | |  |  |
| core | |         | helper - uses    |                    | ------------------------------------ |      |      |      |      |      | |  |  |
| core | |         | existing         |                    | -----                                |      |      |      |      |      | |  |  |
| core | |         | LOG_DEBUG_FILE   |                    |                                      |      |      |      |      |      | |  |  |
| core | |         | from ruc         |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | verify_ |                  | ################## | Path and Variable Verification       | 64   | 59   | 4    |      |      | |  |  |
| core | | path    |                  | ################## |                                      |      |      |      |      |      | |  |  |
| core | |         |                  | ######             |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | verify_ |                  |                    |                                      | 25   | 124  | 4    |      |      | |  |  |
| core | | var     |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | essenti |                  | ################## | Module Verification                  | 26   | 154  | 1    |      |      | |  |  |
| core | | al_chec |                  | ################## |                                      |      |      |      |      |      | |  |  |
| core | | k       |                  | ######             |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | verify_ |                  |                    |                                      | 97   | 181  | 3    |      |      | |  |  |
| core | | module  |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | validat |                  |                    |                                      | 29   | 279  | 1    |      |      | |  |  |
| core | | e_modul |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | | e       |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | verify_ |                  | ################## | Function and Dependency Verification | 23   | 313  | 1    |      |      | |  |  |
| core | | functio |                  | ################## |                                      |      |      |      |      |      | |  |  |
| core | | n_depen |                  | ######             |                                      |      |      |      |      |      | |  |  |
| core | | dencies |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | verify_ |                  |                    |                                      | 34   | 337  | 2    |      |      | |  |  |
| core | | functio |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | | n       |                  |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
| core | | init_ve | Initialize       |                    |                                      | 16   | 373  | 1    |      |      | |  |  |
| core | | rificat | verification     |                    |                                      |      |      |      |      |      | |  |  |
| core | | ion     | system           |                    |                                      |      |      |      |      |      | |  |  |
| core | +                                                                                                                           + |  |  |
<!-- OPS FUNCTIONS -->
| ops | /home/es/lab/lib/ops/[32maux[0m - Contains [31m731[0m Lines and [33m10[0m Functions |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | Func    | Arguments        | Shortname          | Description                          | Size | Loc  | file | lib  | src  | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | aux-fun |                  | overview functions | Shows a summary of selected          | 4    | 35   | 1    |      |      | |  |  |
| ops | |         |                  |                    | functions in the script, displaying  |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | their usage, shortname, and          |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | description                          |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | aux-var |                  | overview variables | Displays an overview of specific     | 3    | 43   | 1    |      |      | |  |  |
| ops | |         |                  |                    | variables defined in the             |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | configuration file, showing their    |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | names, values, and usage across      |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | different files                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | aux-log | Logging function |                    |                                      | 5    | 48   | 1    |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | aux-ffl | <function>       | function folder    | Recursively processes files in a     | 80   | 57   | 2    |      |      | |  |  |
| ops | |         | <flag> <path>    | loop               | directory and its subdirectories     |      |      |      |      |      | |  |  |
| ops | |         | [max_depth]      |                    | using a specified function,          |      |      |      |      |      | |  |  |
| ops | |         | [current_depth]  |                    | allowing for additional arguments    |      |      |      |      |      | |  |  |
| ops | |         | [extra_args ..]  |                    | to be passed                         |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | aux-laf | <file name>      | list all functions | Lists all functions in a file,       | 229  | 141  | 3    | 10   |      | |  |  |
| ops | |         | [-t] [-b]        |                    | displaying their usage, shortname,   |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | and description. Supports            |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | truncation and line break options    |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | for better readability               |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | aux-acu | <sort mode |       | analyze config     | Analyzes the usage of variables      | 250  | 374  | 3    | 8    |      | |  |
| ops | |         | -o|-a|""|>       | usage              | from a config file across target     |      |      |      |      |      | |  |  |
| ops | |         | <config file or  |                    | folders, displaying variable names,  |      |      |      |      |      | |  |  |
| ops | |         | directory>       |                    | values, and occurrence counts in     |      |      |      |      |      | |  |  |
| ops | |         | <target          |                    | various files                        |      |      |      |      |      | |  |  |
| ops | |         | folder1>         |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | [target folder2  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | ...]             |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | aux-mev | <var_name>       | main eval variable | Prompts the user to input or         | 17   | 628  | 1    | 17   |      | |  |  |
| ops | |         | <prompt_message> |                    | confirm a variable's value,          |      |      |      |      |      | |  |  |
| ops | |         |  <current_value> |                    | allowing for easy customization of   |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | script parameters                    |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | aux-nos | <function_name>  | main display       | Logs a function's execution status   | 7    | 649  | 1    | 44   |      | |  |  |
| ops | |         | <status>         | notification       | with a timestamp, providing a        |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | simple way to track script progress  |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | and debugging information            |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | aux-flc | <function_name>  | function library   | Displays the source code of a        | 38   | 660  | 1    |      |      | |  |  |
| ops | |         |                  | cat                | specified function from the library  |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | folder, including its description,   |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | shortname, and usage                 |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | aux-use |                  | function usage     | Displays the usage information,      | 30   | 702  | 5    | 38   |      | |  |  |
| ops | |         |                  | information        | shortname, and description of the    |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | calling function, helping users      |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | understand how to use it             |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | /home/es/lab/lib/ops/[32mgpu[0m - Contains [31m1170[0m Lines and [33m27[0m Functions |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | Func    | Arguments        | Shortname          | Description                          | Size | Loc  | file | lib  | src  | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | _gpu_in | Initialize       |                    | ==================================== | 12   | 27   | 5    |      |      | |  |  |
| ops | | it_colo | color constants  |                    | ==================================== |      |      |      |      |      | |  |  |
| ops | | rs      |                  |                    | ====                                 |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | _gpu_va | Validate PCI ID  |                    |                                      | 4    | 41   | 6    |      |      | |  |  |
| ops | | lidate_ | format           |                    |                                      |      |      |      |      |      | |  |  |
| ops | | pci_id  |                  |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | _gpu_ex | Extract vendor   |                    |                                      | 18   | 47   |      |      |      | |  |  |
| ops | | tract_v | and device IDs   |                    |                                      |      |      |      |      |      | |  |  |
| ops | | endor_d | from lspci       |                    |                                      |      |      |      |      |      | |  |  |
| ops | | evice_i | output           |                    |                                      |      |      |      |      |      | |  |  |
| ops | | d       |                  |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | _gpu_ge | Get current      |                    |                                      | 11   | 67   |      |      |      | |  |  |
| ops | | t_curre | driver for a     |                    |                                      |      |      |      |      |      | |  |  |
| ops | | nt_driv | PCI device       |                    |                                      |      |      |      |      |      | |  |  |
| ops | | er      |                  |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | _gpu_is | Check if device  |                    |                                      | 4    | 80   | 2    |      |      | |  |  |
| ops | | _gpu_de | is GPU-related   |                    |                                      |      |      |      |      |      | |  |  |
| ops | | vice    | (VGA/3D/Audio)   |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | _gpu_lo | Load             |                    |                                      | 11   | 86   |      |      |      | |  |  |
| ops | | ad_conf | configuration    |                    |                                      |      |      |      |      |      | |  |  |
| ops | | ig      | file if          |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | available        |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | _gpu_ge | Get PCI IDs      |                    |                                      | 25   | 99   |      |      |      | |  |  |
| ops | | t_confi | from             |                    |                                      |      |      |      |      |      | |  |  |
| ops | | g_pci_i | hostname-based   |                    |                                      |      |      |      |      |      | |  |  |
| ops | | ds      | configuration    |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | _gpu_fi | Find all GPU     |                    |                                      | 25   | 126  |      |      |      | |  |  |
| ops | | nd_all_ | devices via      |                    |                                      |      |      |      |      |      | |  |  |
| ops | | gpus    | lspci scan       |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | _gpu_ge | Get target GPUs  |                    |                                      | 62   | 153  |      |      |      | |  |  |
| ops | | t_targe | for processing   |                    |                                      |      |      |      |      |      | |  |  |
| ops | | t_gpus  | (handles all     |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | the logic for    |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | determining      |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | which GPUs to    |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | process)         |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | _gpu_en | Ensure VFIO      |                    |                                      | 21   | 217  |      |      |      | |  |  |
| ops | | sure_vf | modules are      |                    |                                      |      |      |      |      |      | |  |  |
| ops | | io_modu | loaded           |                    |                                      |      |      |      |      |      | |  |  |
| ops | | les     |                  |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | _gpu_un | Unbind device    |                    |                                      | 22   | 240  | 2    |      |      | |  |  |
| ops | | bind_de | from current     |                    |                                      |      |      |      |      |      | |  |  |
| ops | | vice    | driver           |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | _gpu_bi | Bind device to   |                    |                                      | 33   | 264  | 2    |      |      | |  |  |
| ops | | nd_devi | specific driver  |                    |                                      |      |      |      |      |      | |  |  |
| ops | | ce      |                  |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | _gpu_ge | Determine        |                    |                                      | 34   | 299  |      |      |      | |  |  |
| ops | | t_host_ | appropriate      |                    |                                      |      |      |      |      |      | |  |  |
| ops | | driver  | host driver for  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | GPU              |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | _gpu_ge | Determine        |                    |                                      | 28   | 335  |      |      |      | |  |  |
| ops | | t_host_ | appropriate      |                    |                                      |      |      |      |      |      | |  |  |
| ops | | driver_ | host driver for  |                    |                                      |      |      |      |      |      | |  |  |
| ops | | paramet | GPU              |                    |                                      |      |      |      |      |      | |  |  |
| ops | | erized  | (parameterized   |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | version)         |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | _gpu_ge | Get PCI IDs      |                    |                                      | 21   | 365  |      |      |      | |  |  |
| ops | | t_confi | from explicit    |                    |                                      |      |      |      |      |      | |  |  |
| ops | | g_pci_i | parameters       |                    |                                      |      |      |      |      |      | |  |  |
| ops | | ds_para | (parameterized   |                    |                                      |      |      |      |      |      | |  |  |
| ops | | meteriz | version)         |                    |                                      |      |      |      |      |      | |  |  |
| ops | | ed      |                  |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | _gpu_ge | Get target GPUs  |                    |                                      | 64   | 388  |      |      |      | |  |  |
| ops | | t_targe | for processing   |                    |                                      |      |      |      |      |      | |  |  |
| ops | | t_gpus_ | (parameterized   |                    |                                      |      |      |      |      |      | |  |  |
| ops | | paramet | version)         |                    |                                      |      |      |      |      |      | |  |  |
| ops | | erized  |                  |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | _gpu_ge | Helper function  |                    |                                      | 54   | 454  | 1    |      |      | |  |  |
| ops | | t_iommu | to get IOMMU     |                    |                                      |      |      |      |      |      | |  |  |
| ops | | _groups | groups for GPU   |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | devices          |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | _gpu_ge | Helper function  |                    |                                      | 92   | 510  |      |      |      | |  |  |
| ops | | t_detai | to get detailed  |                    |                                      |      |      |      |      |      | |  |  |
| ops | | led_dev | GPU device       |                    |                                      |      |      |      |      |      | |  |  |
| ops | | ice_inf | information      |                    |                                      |      |      |      |      |      | |  |  |
| ops | | o       |                  |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | gpu-fun | Shows a summary  |                    | ==================================== | 5    | 608  |      |      |      | |  |  |
| ops | |         | of selected      |                    | ==================================== |      |      |      |      |      | |  |  |
| ops | |         | functions in     |                    | ====                                 |      |      |      |      |      | |  |  |
| ops | |         | the script       |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | gpu-var | Displays an      |                    |                                      | 5    | 615  |      |      |      | |  |  |
| ops | |         | overview of      |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | specific         |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | variables        |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | gpu-nds | Downloads and    |                    |                                      | 35   | 622  |      |      |      | |  |  |
| ops | |         | installs NVIDIA  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | drivers,         |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | blacklisting     |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | Nouveau          |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | gpu-pt1 | Configures       |                    |                                      | 17   | 659  |      |      |      | |  |  |
| ops | |         | initial GRUB     |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | and EFI          |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | settings for     |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | GPU passthrough  |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | gpu-pt2 | Adds necessary   |                    |                                      | 17   | 678  |      |      |      | |  |  |
| ops | |         | kernel modules   |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | for GPU          |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | passthrough      |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | gpu-pt3 | Finalizes or     |                    |                                      | 119  | 697  |      |      |      | |  |  |
| ops | |         | reverts GPU      |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | passthrough      |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | setup            |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | gpu-ptd | Detaches the     |                    |                                      | 89   | 818  |      |      |      | |  |  |
| ops | |         | GPU from the     |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | host system for  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | VM passthrough   |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | gpu-pta | Attaches the     |                    |                                      | 70   | 909  |      |      |      | |  |  |
| ops | |         | GPU back to the  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | host system      |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | gpu-pts | Checks the       |                    |                                      | 190  | 981  |      |      |      | |  |  |
| ops | |         | current status   |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | of the GPU       |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | (complete        |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | detailed         |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | version)         |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | /home/es/lab/lib/ops/[32mnet[0m - Contains [31m117[0m Lines and [33m5[0m Functions |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | Func    | Arguments        | Shortname          | Description                          | Size | Loc  | file | lib  | src  | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | net-fun |                  | overview functions | Displays an overview of specific     | 3    | 30   | 1    |      |      | |  |  |
| ops | |         |                  |                    | functions in the script, showing     |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | their usage, shortname, and          |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | description                          |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | net-var |                  | Displays an        |                                      | 3    | 35   | 1    |      |      | |  |  |
| ops | |         |                  | overview of        |                                      |      |      |      |      |      | |  |  |
| ops | |         |                  | specific           |                                      |      |      |      |      |      | |  |  |
| ops | |         |                  | variables defined  |                                      |      |      |      |      |      | |  |  |
| ops | |         |                  | in the             |                                      |      |      |      |      |      | |  |  |
| ops | |         |                  | configuration      |                                      |      |      |      |      |      | |  |  |
| ops | |         |                  | file, showing      |                                      |      |      |      |      |      | |  |  |
| ops | |         |                  | their names,       |                                      |      |      |      |      |      | |  |  |
| ops | |         |                  | values, and usage  |                                      |      |      |      |      |      | |  |  |
| ops | |         |                  | across different   |                                      |      |      |      |      |      | |  |  |
| ops | |         |                  | files              |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | net-uni | [interactive]    | udev network       | Guides the user through renaming a   | 37   | 42   | 1    |      |      | |  |  |
| ops | |         |                  | interface          | network interface by updating udev   |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | rules and network configuration,     |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | with an option to reboot the system  |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | net-fsr | <service>        | firewall (add)     | Adds a specified service to the      | 16   | 83   | 1    |      |      | |  |  |
| ops | |         |                  | service (and)      | firewalld configuration and reloads  |      |      |      |      |      | |  |  |
| ops | |         |                  | reload             | the firewall. Checks for the         |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | presence of firewall-cmd before      |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | proceeding                           |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | net-fas | <service>        | firewall allow     | Allows a specified service through   | 15   | 103  | 1    |      |      | |  |  |
| ops | |         |                  | service            | the firewall using firewall-cmd,     |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | making the change permanent and      |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | reloading the firewall configuration |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | /home/es/lab/lib/ops/[32mpbs[0m - Contains [31m209[0m Lines and [33m6[0m Functions |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | Func    | Arguments        | Shortname          | Description                          | Size | Loc  | file | lib  | src  | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | pbs-fun |                  | overview functions | show an overview of specific         | 3    | 31   | 1    |      |      | |  |  |
| ops | |         |                  |                    | functions                            |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pbs-var |                  | overview variables | show an overview of specific         | 3    | 37   | 1    |      |      | |  |  |
| ops | |         |                  |                    | variables                            |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pbs-dav |                  | download and       | Download Proxmox GPG key and verify  | 24   | 44   | 1    |      | 1    | |  |  |
| ops | |         |                  | verify             | checksums.                           |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pbs-adr |                  | setup sources.list | Add Proxmox repository to            | 12   | 72   | 1    |      | 1    | |  |  |
| ops | |         |                  |                    | sources.list if not already present. |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pbs-rda | <datastore_confi | restore datastore  | Restore datastore configuration      | 39   | 88   | 1    |      | 1    | |  |  |
| ops | |         | g>               |                    | file with given parameters.          |      |      |      |      |      | |  |  |
| ops | |         | <datastore_name> |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         |                  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <datastore_path> |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pbs-mon | [option]         | pbs monitor        | Monitors and displays various        | 79   | 131  | 2    |      |      | |  |  |
| ops | |         |                  |                    | aspects of the Proxmox Backup Server |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | /home/es/lab/lib/ops/[32mpve[0m - Contains [31m1022[0m Lines and [33m15[0m Functions |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | Func    | Arguments        | Shortname          | Description                          | Size | Loc  | file | lib  | src  | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | pve-fun | <script_path>    | overview functions | Displays an overview of specific     | 22   | 40   | 1    |      |      | |  |  |
| ops | |         |                  |                    | Proxmox Virtual Environment (PVE)    |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | related functions in the script,     |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | showing their usage, shortname, and  |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | description                          |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pve-var | <config_file>    | overview variables | Displays an overview of              | 28   | 66   | 1    |      |      | |  |  |
| ops | |         | <analysis_dir>   |                    | PVE-specific variables defined in    |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | the configuration file, showing      |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | their names, values, and usage       |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | across different files               |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pve-dsr |                  | disable repository | Disables specified Proxmox           | 29   | 98   | 1    |      | 1    | |  |  |
| ops | |         |                  |                    | repository files by commenting out   |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | 'deb' lines, typically used to       |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | manage repository sources            |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pve-rsn |                  | remove sub notice  | Removes the Proxmox subscription     | 26   | 131  | 1    |      | 1    | |  |  |
| ops | |         |                  |                    | notice by modifying the web          |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | interface JavaScript file, with an   |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | option to restart the pveproxy       |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | service                              |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pve-clu |                  | container list     | Updates the Proxmox VE Appliance     | 18   | 161  | 1    |      | 1    | |  |  |
| ops | |         |                  | update             | Manager (pveam) container template   |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | list                                 |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pve-cdo |                  | container          | Downloads a specified container      | 46   | 183  | 2    |      | 1    | |  |  |
| ops | |         |                  | downloads          | template to a given storage          |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | location, with error handling and    |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | options to list available templates  |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pve-cbm | <vmid> <mphost>  | container          | Configures a bind mount for a        | 42   | 233  | 1    |      | 1    | |  |  |
| ops | |         | <mpcontainer>    | bindmount          | specified Proxmox container,         |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | linking a host directory to a        |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | container directory                  |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pve-ctc | <id> <template>  | container create   | Sets up different containers         | 78   | 279  | 2    |      | 1    | |  |  |
| ops | |         | <hostname>       |                    | specified in cfg/env/site.           |      |      |      |      |      | |  |  |
| ops | |         | <storage>        |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <rootfs_size>    |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <memory> <swap>  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <nameserver>     |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <searchdomain>   |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <password>       |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <cpus>           |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <privileged>     |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <ip_address>     |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <cidr>           |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <gateway>        |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <ssh_key_file>   |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <net_bridge>     |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <net_nic>        |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pve-cto | <start|stop|enab | container toggle   | Manages multiple Proxmox containers  | 82   | 361  | 2    |      |      | |  |  |
| ops | |         | le|disable>      |                    | by starting, stopping, enabling, or  |      |      |      |      |      | |  |  |
| ops | |         | <containers|all> |                    | disabling them, supporting           |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | individual IDs, ranges, or all       |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | containers                           |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pve-vmd | Usage |  pve-vmd   | vm shutdown hook   | Deploys or modifies the VM shutdown  | 75   | 447  | 2    |      |      | |  |
| ops | |         | <operation>      |                    | hook for GPU reattachment            |      |      |      |      |      | |  |  |
| ops | |         | <vm_id>          |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <hook_script>    |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <lib_ops_dir>    |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | [<vm_id2> ...]   |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pve-vmc | <id> <name>      | virtual machine    | Sets up different virtual machines   | 72   | 583  | 2    |      | 1    | |  |  |
| ops | |         | <ostype>         | create             | specified in cfg/env/site.           |      |      |      |      |      | |  |  |
| ops | |         | <machine> <iso>  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <boot> <bios>    |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <efidisk>        |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <scsihw>         |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <agent> <disk>   |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <sockets>        |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <cores> <cpu>    |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <memory>         |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <balloon> <net>  |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pve-vms | <vm_id>          | vm start get       | Starts a VM on the current node or   | 82   | 659  | 2    |      |      | |  |  |
| ops | |         | <cluster_nodes_s | shutdown           | migrates it from another node, with  |      |      |      |      |      | |  |  |
| ops | |         | tr> <pci0_id>    |                    | an option to shut down the source    |      |      |      |      |      | |  |  |
| ops | |         | <pci1_id>        |                    | node after migration                 |      |      |      |      |      | |  |  |
| ops | |         | <core_count_on>  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <core_count_off> |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         |                  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <usb_devices_str |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | >                |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <pve_conf_path>  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | [s |  optional,    |                    |                                      |      |      |      |      |      | |  |
| ops | |         | shutdown other   |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | node]            |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pve-vmg | <vm_id>          | vm get start       | Migrates a VM from a remote node to  | 72   | 745  | 3    |      |      | |  |  |
| ops | |         | <cluster_nodes_s |                    | the current node, handling PCIe      |      |      |      |      |      | |  |  |
| ops | |         | tr> <pci0_id>    |                    | passthrough disable/enable during    |      |      |      |      |      | |  |  |
| ops | |         | <pci1_id>        |                    | the process                          |      |      |      |      |      | |  |  |
| ops | |         | <core_count_on>  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <core_count_off> |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         |                  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <usb_devices_str |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | >                |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <pve_conf_path>  |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pve-vpt | <vm_id>          | vm passthrough     | Toggles PCIe passthrough             | 99   | 821  | 3    |      |      | |  |  |
| ops | |         | <on|off>         | toggle             | configuration for a specified VM,    |      |      |      |      |      | |  |  |
| ops | |         | <pci0_id>        |                    | modifying its configuration file to  |      |      |      |      |      | |  |  |
| ops | |         | <pci1_id>        |                    | enable or disable passthrough        |      |      |      |      |      | |  |  |
| ops | |         | <core_count_on>  |                    | devices                              |      |      |      |      |      | |  |  |
| ops | |         | <core_count_off> |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         |                  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <usb_devices_str |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | >                |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <pve_conf_path>  |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | pve-vck | <vm_id>          | vm check node      | Checks and reports which node in     | 99   | 924  | 4    |      |      | |  |  |
| ops | |         | <cluster_nodes_a |                    | the Proxmox cluster is currently     |      |      |      |      |      | |  |  |
| ops | |         | rray>            |                    | hosting a specified VM               |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | /home/es/lab/lib/ops/[32msrv[0m - Contains [31m335[0m Lines and [33m8[0m Functions |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | Func    | Arguments        | Shortname          | Description                          | Size | Loc  | file | lib  | src  | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | srv-fun |                  | overview functions | Displays an overview of specific     | 3    | 33   | 1    |      |      | |  |  |
| ops | |         |                  |                    | NFS-related functions in the         |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | script, showing their usage,         |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | shortname, and description           |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | srv-var |                  | overview variables | Displays an overview of              | 3    | 39   | 1    |      |      | |  |  |
| ops | |         |                  |                    | NFS-specific variables defined in    |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | the configuration file, showing      |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | their names, values, and usage       |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | across different files               |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | nfs-set | <nfs_header>     | nfs setup          | Sets up an NFS share by prompting    | 15   | 46   | 1    |      | 1    | |  |  |
| ops | |         | <shared_folder>  |                    | for necessary information (NFS       |      |      |      |      |      | |  |  |
| ops | |         | <nfs_options>    |                    | header, shared folder, and options)  |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | and applying the configuration       |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | nfs-apl | <nfs_header>     | nfs apply config   | Applies NFS configuration by         | 30   | 65   | 2    |      |      | |  |  |
| ops | |         | <shared_folder>  |                    | creating the shared folder if        |      |      |      |      |      | |  |  |
| ops | |         | <nfs_options>    |                    | needed, updating /etc/exports, and   |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | restarting the NFS server            |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | nfs-mon | [option]         | nfs monitor        | Monitors and displays various        | 68   | 99   | 2    |      |      | |  |  |
| ops | |         |                  |                    | aspects of the NFS server            |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | smb-set | <smb_header>     | samba setup 1      | Sets up a Samba share by prompting   | 30   | 171  | 1    |      | 2    | |  |  |
| ops | |         | <shared_folder>  |                    | for missing configuration details    |      |      |      |      |      | |  |  |
| ops | |         | <username>       |                    | and applying the configuration.      |      |      |      |      |      | |  |  |
| ops | |         | <smb_password>   |                    | Handles various share parameters     |      |      |      |      |      | |  |  |
| ops | |         | <writable_yesno> |                    | including permissions, guest         |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | access, and file masks               |      |      |      |      |      | |  |  |
| ops | |         | <guestok_yesno>  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <browseable_yesn |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | o>               |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <create_mask>    |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <dir_mask>       |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <force_user>     |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <force_group>    |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | smb-apl | <smb_header>     | samba apply config | Applies Samba configuration by       | 58   | 205  | 2    |      |      | |  |  |
| ops | |         | <shared_folder>  |                    | creating the shared folder if        |      |      |      |      |      | |  |  |
| ops | |         | <username>       |                    | needed, updating cfg/env/site. with  |      |      |      |      |      | |  |  |
| ops | |         | <smb_password>   |                    | share details, restarting the Samba  |      |      |      |      |      | |  |  |
| ops | |         | <writable_yesno> |                    | service, and setting up user         |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | passwords. Supports both             |      |      |      |      |      | |  |  |
| ops | |         | <guestok_yesno>  |                    | user-specific and 'nobody' shares    |      |      |      |      |      | |  |  |
| ops | |         | <browseable_yesn |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | o>               |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <create_mask>    |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <dir_mask>       |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <force_user>     |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <force_group>    |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | smb-mon | [option]         | smb monitor        | Monitors and displays various        | 68   | 267  | 2    |      |      | |  |  |
| ops | |         |                  |                    | aspects of the SMB server            |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | /home/es/lab/lib/ops/[32msto[0m - Contains [31m875[0m Lines and [33m17[0m Functions |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | Func    | Arguments        | Shortname          | Description                          | Size | Loc  | file | lib  | src  | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | sto-fun |                  | overview functions | Displays an overview of specific     | 3    | 42   | 1    |      |      | |  |  |
| ops | |         |                  |                    | functions in the script, showing     |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | their usage, shortname, and          |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | description                          |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sto-var |                  | overview variables | Displays an overview of specific     | 3    | 48   | 1    |      |      | |  |  |
| ops | |         |                  |                    | variables defined in the             |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | configuration file, showing their    |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | names, values, and usage across      |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | different files                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sto-fea |                  | fstab entry auto   | Adds auto-mount entries for devices  | 34   | 55   | 1    |      |      | |  |  |
| ops | |         |                  |                    | to /etc/fstab using blkid. Allows    |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | user to select a device UUID and     |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | automatically creates the            |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | appropriate fstab entry              |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sto-fec | <line_number>    | fstab entry custom | Adds custom entries to /etc/fstab    | 35   | 93   | 1    |      |      | |  |  |
| ops | |         | <mount_point>    |                    | using device UUIDs. Allows user to   |      |      |      |      |      | |  |  |
| ops | |         | <filesystem>     |                    | specify mount point, filesystem,     |      |      |      |      |      | |  |  |
| ops | |         | <mount_options>  |                    | mount options, and other parameters  |      |      |      |      |      | |  |  |
| ops | |         | <fsck_pass_numbe |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | r>               |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <mount_at_boot_p |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | riority>"        |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sto-nfs | [server_ip]      | network file share | Mounts an NFS share interactively    | 39   | 132  | 1    |      | 1    | |  |  |
| ops | |         | [shared_folder]  |                    | or with provided arguments           |      |      |      |      |      | |  |  |
| ops | |         | [mount_point]    |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | [options]        |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sto-bfs | <folder_name>    | transforming       | Transforms a folder into a Btrfs     | 48   | 175  | 2    |      |      | |  |  |
| ops | | -tra    | <user_name> <C>  | folder subvolume   | subvolume, optionally setting        |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | attributes (e.g., disabling COW).    |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | Handles multiple folders,            |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | preserving content and ownership.    |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sto-bfs | <device1>        | btrfs raid 1       | Creates a Btrfs RAID 1 filesystem    | 38   | 227  | 1    |      | 1    | |  |  |
| ops | | -ra1    | <device2>        |                    | on two specified devices, mounts     |      |      |      |      |      | |  |  |
| ops | |         | <mount_point>    |                    | it, and optionally adds an entry to  |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | /etc/fstab                           |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sto-bfs | <path>           | check subvolume    | Checks and lists subvolume status    | 52   | 269  | 1    |      |      | |  |  |
| ops | | -csf    | <folder_type |     | folder             | of folders in a specified path.      |      |      |      |      |      | |  |
| ops | |         | 1=regular,       |                    | Supports filtering by folder type    |      |      |      |      |      | |  |  |
| ops | |         | 2=hidden,        |                    | (regular, hidden, or both) and       |      |      |      |      |      | |  |  |
| ops | |         | 3=both>          |                    | subvolume status.                    |      |      |      |      |      | |  |  |
| ops | |         | <yes=show        |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | subvolumes,      |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | no=show          |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | non-subvolumes,  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | all=show all>    |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sto-bfs | <configname>     | snapper home       | Creates a new Snapper snapshot for   | 38   | 325  | 1    |      |      | |  |  |
| ops | | -shc    |                  | create             | the specified configuration or       |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | automatically selects a 'home_*'     |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | configuration if multiple exist      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sto-bfs | <configname>     | snapper home       | Deletes a specified Snapper          | 44   | 366  | 2    |      |      | |  |  |
| ops | | -shd    | <snapshot>       | delete             | snapshot from a given configuration  |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | or automatically selects a 'home_*'  |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | configuration if multiple exist      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sto-bfs | <configname>     | snapper home list  | Lists Snapper snapshots for the      | 38   | 414  | 1    |      |      | |  |  |
| ops | | -shl    |                  |                    | specified configuration or           |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | automatically selects a 'home_*'     |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | configuration if multiple exist      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sto-bfs | <snapshot        | snapshot flat      | Resyncs a Btrfs snapshot subvolume   | 22   | 456  | 1    |      |      | |  |  |
| ops | | -sfr    | subvolume>       | resync             | to a flat folder using rsync,        |      |      |      |      |      | |  |  |
| ops | |         | <target folder>  |                    | excluding specific directories       |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | (.snapshots and .ssh) and            |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | preserving attributes                |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sto-bfs | <user>           | home user backups  | Creates a backup subvolume for a     | 139  | 481  | 1    |      |      | |  |  |
| ops | | -hub    | <snapshots |       |                    | user's home directory on a backup    |      |      |      |      |      | |  |
| ops | |         | "all">           |                    | drive, then sends and receives       |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | Btrfs snapshots incrementally,       |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | managing full and incremental        |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | backups                              |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sto-bfs | <parent          | subvolume nested   | Recursively deletes a Btrfs parent   | 94   | 624  | 2    |      |      | |  |  |
| ops | | -snd    | subvolume>       | delete             | subvolume and all its nested child   |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | subvolumes, with options for         |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | interactive mode and forced deletion |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sto-zfs | <pool_name>      | zfs create pool    | Creates a ZFS pool on a specified    | 42   | 723  | 1    |      |      | |  |  |
| ops | | -cpo    | <drive_name_or_p |                    | drive in a Proxmox VE environment    |      |      |      |      |      | |  |  |
| ops | |         | ath>             |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sto-zfs | <pool_name>      | zfs directory      | Creates a new ZFS dataset or uses    | 43   | 770  | 1    |      | 1    | |  |  |
| ops | | -dim    | <dataset_name>   | mount              | an existing one, sets its            |      |      |      |      |      | |  |  |
| ops | |         | <mountpoint_path |                    | mountpoint, and ensures it's         |      |      |      |      |      | |  |  |
| ops | |         | >                |                    | mounted at the specified path        |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sto-zfs | <sourcepoolname> | zfs dataset backup | Creates and sends ZFS snapshots      | 59   | 817  | 1    |      |      | |  |  |
| ops | | -dbs    |                  |                    | from a source pool to a destination  |      |      |      |      |      | |  |  |
| ops | |         | <destinationpool |                    | pool. Supports initial full sends    |      |      |      |      |      | |  |  |
| ops | |         | name>            |                    | and incremental sends for efficiency |      |      |      |      |      | |  |  |
| ops | |         | <datasetname>    |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | /home/es/lab/lib/ops/[32msys[0m - Contains [31m921[0m Lines and [33m18[0m Functions |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | Func    | Arguments        | Shortname          | Description                          | Size | Loc  | file | lib  | src  | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | sys-fun |                  | overview functions | Shows a summary of specific          | 4    | 40   | 1    |      |      | |  |  |
| ops | |         |                  |                    | functions in the script, displaying  |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | their usage, shortname, and          |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | description                          |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sys-var |                  | overview variables | Displays an overview of specific     | 3    | 48   | 1    |      |      | |  |  |
| ops | |         |                  |                    | variables defined in the             |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | configuration file, showing their    |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | names, values, and usage across      |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | different files                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sys-gio | sys-gio [commit  | Performs status    | Manages git operations, ensuring     | 41   | 55   | 2    |      |      | |  |  |
| ops | |         | message]         | check, pull,       | the local repository syncs with the  |      |      |      |      |      | |  |  |
| ops | |         |                  | commit, and push   | remote.                              |      |      |      |      |      | |  |  |
| ops | |         |                  | operations as      |                                      |      |      |      |      |      | |  |  |
| ops | |         |                  | needed.            |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sys-dpa |                  | detect package all | Detects the system's package manager | 16   | 100  | 3    |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sys-upa |                  | update packages    | Updates and upgrades system          | 37   | 120  | 1    |      | 1    | |  |  |
| ops | |         |                  | all                | packages using the detected package  |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | manager                              |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sys-ipa | <pak1> <pak2>    | install packages   | Installs specified packages using    | 49   | 161  | 1    |      | 5    | |  |  |
| ops | |         | ...              | all                | the system's package manager         |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sys-gst | <username>       | git set config     | Configures git globally with a       | 15   | 214  | 1    |      | 1    | |  |  |
| ops | |         | <usermail>       |                    | specified username and email,        |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | essential for proper commit          |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | attribution                          |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sys-sst |                  | setup sysstat      | Installs, enables, and starts the    | 13   | 233  | 1    |      |      | |  |  |
| ops | |         |                  |                    | sysstat service for system           |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | performance monitoring. Modifies     |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | the configuration to ensure it's     |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | enabled                              |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sys-ust | <username>       | user setup         | Creates a new user with a specified  | 28   | 250  | 1    |      | 2    | |  |  |
| ops | |         | <password>       |                    | username and password, prompting     |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | for input if not provided. Verifies  |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | successful user creation             |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sys-sdc | <service>        | systemd setup      | Enables and starts a specified       | 30   | 282  | 1    |      | 2    | |  |  |
| ops | |         |                  | service            | systemd service. Checks if the       |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | service is active and prompts for    |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | continuation if it's not             |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sys-suk | <device_path>    | ssh upload keyfile | Uploads an SSH key from a            | 62   | 316  | 1    |      | 2    | |  |  |
| ops | |         | <mount_point>    |                    | plugged-in device to a specified     |      |      |      |      |      | |  |  |
| ops | |         | <subfolder_path> |                    | folder (default |  /root/.ssh).        |      |      |      |      |      | |  |
| ops | |         |  <upload_path>   |                    | Handles mounting, file copying, and  |      |      |      |      |      | |  |  |
| ops | |         | <file_name>      |                    | unmounting of the device             |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sys-spi | <user> <keyname> | ssh private        | Appends a private SSH key            | 43   | 382  | 1    |      |      | |  |  |
| ops | |         |                  | identifier         | identifier to the SSH config file    |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | for a specified user. Creates the    |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | .ssh directory and config file if    |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | they don't exist                     |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sys-sks | client-side      | ssh key swap       | Generates an SSH key pair and        | 110  | 429  | 5    |      | 1    | |  |  |
| ops | |         | generation |       |                    | handles the transfer process         |      |      |      |      |      | |  |
| ops | |         | sys-sks -c [-d]  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <server_address> |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         |  <key_name>      |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | [encryption_type |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | ] / server-side  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | generation |       |                    |                                      |      |      |      |      |      | |  |
| ops | |         | sys-sks -s [-d]  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <client_address> |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         |  <key_name>      |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | [encryption_type |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | ]                |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sys-sak | Usage |  sys-sak   | Provides           | Appends the content of a specified   | 59   | 543  | 5    |      | 2    | |  |
| ops | |         | -c               | informational      | public SSH key file to the           |      |      |      |      |      | |  |  |
| ops | |         | <server_address> | output and         | authorized_keys file.                |      |      |      |      |      | |  |  |
| ops | |         |  <key_name>      | restarts the SSH   |                                      |      |      |      |      |      | |  |  |
| ops | |         | *for             | service.           |                                      |      |      |      |      |      | |  |  |
| ops | |         | client-side      |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | operation ///    |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | sys-sak -s       |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <client_address> |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         |  <key_name>      |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | *for             |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | server-side      |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | operation        |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sys-loi | <ip array |        | loop operation ip  | Loops a specified SSH operation      | 45   | 606  |      |      |      | |  |
| ops | |         | hy,ct>           |                    | (bypass StrictHostKeyChecking or     |      |      |      |      |      | |  |  |
| ops | |         | <operation |       |                    | refresh known_hosts) through a       |      |      |      |      |      | |  |
| ops | |         | bypass =         |                    | range of IPs defined in the          |      |      |      |      |      | |  |  |
| ops | |         | Perform initial  |                    | configuration                        |      |      |      |      |      | |  |  |
| ops | |         | SSH login to     |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | bypass           |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | StrictHostKeyChe |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | cking / refresh  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | = Remove the     |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | SSH key for the  |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | given IP from    |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | known_hosts>     |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sys-sca | <usershortcut>   | ssh custom aliases | Resolves custom SSH aliases using    | 156  | 655  |      |      | 4    | |  |  |
| ops | |         | <servershortcut> |                    | the configuration file. Supports     |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | connecting to single or multiple     |      |      |      |      |      | |  |  |
| ops | |         | <ssh_users_array |                    | servers, executing commands remotely |      |      |      |      |      | |  |  |
| ops | |         | _name>           |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <all_ip_arrays_a |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | rray_name>       |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | <array_aliases_a |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | rray_name>       |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | [command]        |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sys-gre | Usage |  sys-gre   | GRE |  Git Reset     | An interactive Bash function that    | 69   | 815  | 1    |      |      | |
| ops | |         | # Then follow    | Explorer           | guides users through Git history     |      |      |      |      |      | |  |  |
| ops | |         | prompts, e.g.,   |                    | navigation, offering options for     |      |      |      |      |      | |  |  |
| ops | |         | enter '2' for    |                    | reset type and subsequent actions,   |      |      |      |      |      | |  |  |
| ops | |         | commits, '3'     |                    | with built-in safeguards and         |      |      |      |      |      | |  |  |
| ops | |         | for hard reset,  |                    | explanations.                        |      |      |      |      |      | |  |  |
| ops | |         | '2' to create    |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | new branch 'feat |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | sys-hos | <ip_address>     | add host           | Adds or updates a host entry in      | 34   | 888  | 1    |      | 5    | |  |  |
| ops | |         | <hostname>       |                    | /etc/hosts. If IP or hostname is     |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | empty, logs an error and exits.      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | /home/es/lab/lib/ops/[32musr[0m - Contains [31m674[0m Lines and [33m14[0m Functions |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | Func    | Arguments        | Shortname          | Description                          | Size | Loc  | file | lib  | src  | |  |  |
| ops | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| ops | | usr-fun |                  | overview functions | Shows a summary of selected          | 4    | 38   | 1    |      |      | |  |  |
| ops | |         |                  |                    | functions in the script, displaying  |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | their usage, shortname, and          |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | description                          |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | usr-var |                  | overview variables | Displays an overview of specific     | 3    | 45   | 1    |      |      | |  |  |
| ops | |         |                  |                    | variables defined in the             |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | configuration file, showing their    |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | names, values, and usage across      |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | different files                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | usr-ckp | <profile_number> | change konsole     | Changes the Konsole profile for the  | 56   | 52   | 1    |      |      | |  |  |
| ops | |         |                  | profile            | current user by updating the         |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | konsolerc file                       |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | usr-vsf |                  | variable select    | Prompts the user to select a file    | 10   | 112  | 1    |      |      | |  |  |
| ops | |         |                  | filename           | from the current directory by        |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | displaying a numbered list of files  |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | and returning the chosen filename    |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | usr-cff | <path>           | count files folder | Counts files in directories based    | 44   | 126  | 1    |      |      | |  |  |
| ops | |         | <folder_type |     |                    | on specified visibility (regular,    |      |      |      |      |      | |  |
| ops | |         | 1=regular,       |                    | hidden, or both). Displays results   |      |      |      |      |      | |  |  |
| ops | |         | 2=hidden,        |                    | sorted by directory name             |      |      |      |      |      | |  |  |
| ops | |         | 3=both>          |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | usr-duc | <path1> <path2>  | data usage         | Compares data usage between two      | 63   | 174  | 1    |      |      | |  |  |
| ops | |         | <depth>          | comparison         | paths up to a specified depth.       |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | Displays results in a tabular        |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | format with color-coded differences  |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | usr-cif | <path>           | cat in folder      | Concatenates and displays the        | 22   | 241  | 1    |      |      | |  |  |
| ops | |         |                  |                    | contents of all files within a       |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | specified folder, separating each    |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | file's content with a line of dashes |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | usr-rsf | <foldername>     | replace strings    | Replaces strings in files within a   | 46   | 267  | 1    |      |      | |  |  |
| ops | |         | <old_string>     | folder             | specified folder and its             |      |      |      |      |      | |  |  |
| ops | |         | <new_string>     |                    | subfolders. If in a git repository,  |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | it stages changes and shows the diff |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | usr-rsd | <source_path>    | rsync source (to)  | Performs an rsync operation from a   | 39   | 317  | 1    |      |      | |  |  |
| ops | |         | <destination_pat | destination        | source to a destination path.        |      |      |      |      |      | |  |  |
| ops | |         | h>               |                    | Displays files to be transferred     |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | and prompts for confirmation before  |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | proceeding                           |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | usr-swt | <-r for          | sheduled wakeup    | Schedules a system wake-up using     | 101  | 360  | 2    |      |      | |  |  |
| ops | |         | relative or -a   | timer              | rtcwake. Supports absolute or        |      |      |      |      |      | |  |  |
| ops | |         | for absolute>    |                    | relative time input and different    |      |      |      |      |      | |  |  |
| ops | |         | <time> <state>   |                    | sleep states (mem/disk)              |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | usr-adr |                  | adding line (to)   | Adds a specific line to a target if  | 38   | 465  | 1    |      | 1    | |  |  |
| ops | |         |                  | target             | not already present                  |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | usr-cap | <file> <line>    | check append       | Appends a line to a file if it does  | 19   | 507  | 1    |      |      | |  |  |
| ops | |         |                  | create             | not already exist, preventing        |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | duplicate entries and providing      |      |      |      |      |      | |  |  |
| ops | |         |                  |                    | feedback on the operation            |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | usr-rif | Options |  -d      | Usage |  usr-rif     | Replaces all occurrences of a        | 118  | 530  | 4    |      |      | |
| ops | |         | (dry run), -r    | [-d] [-r] [-i]     | string in files within a given       |      |      |      |      |      | |  |  |
| ops | |         | (recursive), -i  | <path>             | folder                               |      |      |      |      |      | |  |  |
| ops | |         | (interactive)    | <old_string>       |                                      |      |      |      |      |      | |  |  |
| ops | |         |                  | <new_string>       |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
| ops | | usr-ans | Usage |  usr-ans   | ansible            | Navigates to the Ansible project     | 23   | 652  | 2    |      |      | |  |
| ops | |         | <ansible_pro_pat | deployment desk    | directory, runs the playbook, then   |      |      |      |      |      | |  |  |
| ops | |         | h>               |                    | returns to the original directory    |      |      |      |      |      | |  |  |
| ops | |         | <ansible_site_pa |                    |                                      |      |      |      |      |      | |  |  |
| ops | |         | th>              |                    |                                      |      |      |      |      |      | |  |  |
| ops | +                                                                                                                           + |  |  |
<!-- GEN FUNCTIONS -->
| gen | /home/es/lab/lib/gen/[32menv[0m - Contains [31m355[0m Lines and [33m9[0m Functions |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | | Func    | Arguments        | Shortname          | Description                          | Size | Loc  | file | lib  | src  | |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | | update_ | Helper function  |                    |                                      | 23   | 90   | 3    |      |      | |  |  |
| gen | | ecc     | to update        |                    |                                      |      |      |      |      |      | |  |  |
| gen | |         | environment      |                    |                                      |      |      |      |      |      | |  |  |
| gen | |         | controller       |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | env_swi | Switch           |                    |                                      | 13   | 115  | 3    |      |      | |  |  |
| gen | | tch     | environment      |                    |                                      |      |      |      |      |      | |  |  |
| gen | |         | (dev/test/stagin |                    |                                      |      |      |      |      |      | |  |  |
| gen | |         | g/prod)          |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | site_sw | Switch site      |                    |                                      | 20   | 130  | 3    |      |      | |  |  |
| gen | | itch    |                  |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | node_sw | Switch node      |                    |                                      | 13   | 152  | 3    |      |      | |  |  |
| gen | | itch    |                  |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | env_sta | Show current     |                    |                                      | 39   | 167  | 5    |      |      | |  |  |
| gen | | tus     | environment      |                    |                                      |      |      |      |      |      | |  |  |
| gen | |         | status           |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | env_lis | List available   |                    |                                      | 13   | 208  | 2    |      |      | |  |  |
| gen | | t       | environments     |                    |                                      |      |      |      |      |      | |  |  |
| gen | |         | and overrides    |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | env_val | Validate         |                    |                                      | 66   | 223  | 1    |      |      | |  |  |
| gen | | idate   | configuration    |                    |                                      |      |      |      |      |      | |  |  |
| gen | |         | files            |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | env_usa | Show usage       |                    |                                      | 28   | 291  | 2    |      |      | |  |  |
| gen | | ge      |                  |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | main    | Main function    |                    |                                      | 30   | 321  | 2    | 2    |      | |  |  |
| gen | |         | for              |                    |                                      |      |      |      |      |      | |  |  |
| gen | |         | command-line     |                    |                                      |      |      |      |      |      | |  |  |
| gen | |         | usage            |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | /home/es/lab/lib/gen/[32minf[0m - Contains [31m441[0m Lines and [33m9[0m Functions |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | | Func    | Arguments        | Shortname          | Description                          | Size | Loc  | file | lib  | src  | |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | | set_con | Set container    |                    |                                      | 33   | 114  | 2    |      |      | |  |  |
| gen | | tainer_ | defaults (can    |                    |                                      |      |      |      |      |      | |  |  |
| gen | | default | be called to     |                    |                                      |      |      |      |      |      | |  |  |
| gen | | s       | override global  |                    |                                      |      |      |      |      |      | |  |  |
| gen | |         | defaults)        |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | generat | Generate         |                    |                                      | 15   | 149  | 1    |      |      | |  |  |
| gen | | e_ip_se | sequential IP    |                    |                                      |      |      |      |      |      | |  |  |
| gen | | quence  | addresses        |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | define_ | Define a         |                    |                                      | 48   | 166  | 3    |      |      | |  |  |
| gen | | contain | container with   |                    |                                      |      |      |      |      |      | |  |  |
| gen | | er      | minimal          |                    |                                      |      |      |      |      |      | |  |  |
| gen | |         | parameters       |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | define_ | Define multiple  |                    |                                      | 17   | 216  | 2    |      |      | |  |  |
| gen | | contain | containers from  |                    |                                      |      |      |      |      |      | |  |  |
| gen | | ers     | a configuration  |                    |                                      |      |      |      |      |      | |  |  |
| gen | |         | string           |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | set_vm_ | Set VM defaults  |                    |                                      | 25   | 235  | 1    |      |      | |  |  |
| gen | | default |                  |                    |                                      |      |      |      |      |      | |  |  |
| gen | | s       |                  |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | define_ | Define a VM      |                    |                                      | 47   | 262  | 2    |      |      | |  |  |
| gen | | vm      | with minimal     |                    |                                      |      |      |      |      |      | |  |  |
| gen | |         | parameters       |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | define_ | Format |           | Define multiple    |                                      | 24   | 312  | 1    |      |      | |  |
| gen | | vms     | "id1 | name1 | iso1 |
| gen | |         | disk1 | net1 | id2 |
| gen | |         | ame2 | iso2 | disk2 |
| gen | |         | net2 | ..."        |                    |                                      |      |      |      |      |      | |  |
| gen | +                                                                                                                           + |  |  |
| gen | | validat | Validate         |                    |                                      | 50   | 338  | 1    |      |      | |  |  |
| gen | | e_confi | configuration    |                    |                                      |      |      |      |      |      | |  |  |
| gen | | g       |                  |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | show_co | Show             |                    |                                      | 30   | 390  | 1    |      |      | |  |  |
| gen | | nfig_su | configuration    |                    |                                      |      |      |      |      |      | |  |  |
| gen | | mmary   | summary          |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | /home/es/lab/lib/gen/[32msec[0m - Contains [31m294[0m Lines and [33m10[0m Functions |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | | Func    | Arguments        | Shortname          | Description                          | Size | Loc  | file | lib  | src  | |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | | generat | Default length |   | Usage |              | Generate a secure password with      | 13   | 104  | 2    |      |      | |
| gen | | e_secur | 16, Default      | generate_secure_pa | specified length                     |      |      |      |      |      | |  |  |
| gen | | e_passw | special chars |    | ssword [length]    |                                      |      |      |      |      |      | |  |
| gen | | ord     | included         | [exclude_special]  |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | store_s | Usage |            | Generate a secure  |                                      | 14   | 120  | 9    |      |      | |  |
| gen | | ecure_p | store_secure_pas | password and       |                                      |      |      |      |      |      | |  |  |
| gen | | assword | sword            | store it in a      |                                      |      |      |      |      |      | |  |  |
| gen | |         | variable_name    | variable           |                                      |      |      |      |      |      | |  |  |
| gen | |         | [length]         |                    |                                      |      |      |      |      |      | |  |  |
| gen | |         | [exclude_special |                    |                                      |      |      |      |      |      | |  |  |
| gen | |         | ]                |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | generat | Usage |            | Generate multiple  |                                      | 16   | 137  | 2    |      |      | |  |
| gen | | e_servi | generate_service | passwords for      |                                      |      |      |      |      |      | |  |  |
| gen | | ce_pass | _passwords       | different services |                                      |      |      |      |      |      | |  |  |
| gen | | words   |                  |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | create_ | Usage |            | Create a password  |                                      | 13   | 156  | 7    |      |      | |  |
| gen | | passwor | create_password_ | file with proper   |                                      |      |      |      |      |      | |  |  |
| gen | | d_file  | file filename    | permissions        |                                      |      |      |      |      |      | |  |  |
| gen | |         | password         |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | load_st | Usage |            | Load passwords     |                                      | 14   | 172  | 2    |      |      | |  |
| gen | | ored_pa | load_stored_pass | from secure        |                                      |      |      |      |      |      | |  |  |
| gen | | sswords | words            | storage            |                                      |      |      |      |      |      | |  |  |
| gen | |         | [password_dir]   |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | get_pas | Usage |            | Get the            |                                      | 18   | 189  | 1    |      |      | |  |
| gen | | sword_d | get_password_dir | appropriate        |                                      |      |      |      |      |      | |  |  |
| gen | | irector | ectory           | password           |                                      |      |      |      |      |      | |  |  |
| gen | | y       |                  | directory based    |                                      |      |      |      |      |      | |  |  |
| gen | |         |                  | on system          |                                      |      |      |      |      |      | |  |  |
| gen | |         |                  | capabilities       |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | init_pa | Usage |            | Initialize secure  |                                      | 38   | 210  | 3    |      |      | |  |
| gen | | ssword_ | init_password_ma | password           |                                      |      |      |      |      |      | |  |  |
| gen | | managem | nagement         | management         |                                      |      |      |      |      |      | |  |  |
| gen | | ent     | [password_dir]   |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | init_pa | Usage |            | Initialize         |                                      | 6    | 251  | 1    |      |      | |  |
| gen | | ssword_ | init_password_ma | password           |                                      |      |      |      |      |      | |  |  |
| gen | | managem | nagement_auto    | management with    |                                      |      |      |      |      |      | |  |  |
| gen | | ent_aut |                  | smart directory    |                                      |      |      |      |      |      | |  |  |
| gen | | o       |                  | selection          |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | get_pas | Usage |            | Get password file  |                                      | 14   | 260  | 1    |      |      | |  |
| gen | | sword_f | get_password_fil | path with          |                                      |      |      |      |      |      | |  |  |
| gen | | ile     | e filename       | fallback mechanism |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | get_sec | Usage |            | Get password with  |                                      | 12   | 277  | 1    |      |      | |  |
| gen | | ure_pas | get_secure_passw | smart lookup       |                                      |      |      |      |      |      | |  |  |
| gen | | sword   | ord filename     |                    |                                      |      |      |      |      |      | |  |  |
| gen | |         | [length]         |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | /home/es/lab/lib/gen/[32mssh[0m - Contains [31m49[0m Lines and [33m5[0m Functions |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | | Func    | Arguments        | Shortname          | Description                          | Size | Loc  | file | lib  | src  | |  |  |
| gen | +---------------------------------------------------------------------------------------------------------------------------+ |  |  |
| gen | | set_ssh |                  | !/bin/bash         |                                      | 8    | 3    |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | setup_s |                  |                    |                                      | 8    | 12   | 1    |      |      | |  |  |
| gen | | sh      |                  |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | add_ssh |                  |                    |                                      | 19   | 21   | 1    |      |      | |  |  |
| gen | | _keys   |                  |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | list_ss |                  |                    |                                      | 4    | 41   | 1    |      |      | |  |  |
| gen | | h_keys  |                  |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |
| gen | | remove_ |                  |                    |                                      | 4    | 46   |      |      |      | |  |  |
| gen | | ssh_key |                  |                    |                                      |      |      |      |      |      | |  |  |
| gen | | s       |                  |                    |                                      |      |      |      |      |      | |  |  |
| gen | +                                                                                                                           + |  |  |

<!-- END AUTO-GENERATED SECTION -->

## 🎯 Pure Function Characteristics

### Design Principles
- **Stateless**: No global state dependencies
- **Parameterized**: All inputs via explicit parameters
- **Predictable**: Same inputs always produce same outputs
- **Testable**: Can be tested in isolation

### Usage Pattern
```bash
# Pure function call
function_name "param1" "param2" "param3"

# No environment variables required
# No side effects on global state
# Fully deterministic behavior
```

## 🔧 Integration

To use pure functions in your scripts:

```bash
# Source the required library modules
source "$LIB_CORE_DIR/err"
source "$LIB_OPS_DIR/pve"
source "$LIB_GEN_DIR/inf"

# Call functions with explicit parameters
pve-vmc "101" "node1,node2,node3"
handle_error "component" "message" "ERROR"
```

## 📖 Related Documentation

- **[System Architecture](architecture.md)** - Complete system design
- **[Logging System](logging.md)** - Debug and logging frameworks
- **[Verbosity Controls](verbosity.md)** - Output control mechanisms
