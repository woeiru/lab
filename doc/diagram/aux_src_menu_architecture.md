```mermaid
graph TD
    A[Start: Script Execution ./script_name <args>] --> B(setup_main);

    subgraph main_logic [setup_main]
        direction LR
        B --> B1{Args provided?};
        B1 -- No --> B_Usage(print_usage);
        B_Usage --> B_Exit[Exit];
        B1 -- Yes --> B2{Mode?};
    end

    B2 -- -i (Interactive) --> I_Mode[Interactive Mode Logic];
    B2 -- -x (Execution) --> E_Mode[Execution Mode Logic];
    B2 -- Invalid mode --> B_Usage;

    subgraph I_Mode [setup_interactive_mode]
        direction TB
        IM1["Parse display_choice & section_focus (-s)"];
        IM1 --> IM2{Display choice provided?};
        IM2 -- No --> IM3[Prompt for display_choice];
        IM3 --> IM4(setup_display_menu);
        IM2 -- Yes --> IM4;
        IM4 --> IM5{"Section focus (-s) provided?"};
        IM5 -- Yes --> IM6[Confirm & Execute focused section via setup_executing_mode];
        IM6 --> I_Exit[End Interactive];
        IM5 -- No --> IM7(select_and_execute_sections);
    end

    subgraph select_and_execute_sections
        direction TB
        IM7 --> SES1[Display available sections from MENU_OPTIONS];
        SES1 --> SES2[Prompt user for section(s)];
        SES2 --> SES3{Loop each selected section};
        SES3 -- More sections --> SES4(Call setup_executing_mode for section);
        SES4 --> SES3;
        SES3 -- No more sections --> I_Exit;
    end

    subgraph E_Mode [setup_executing_mode for -x]
        direction TB
        EM1[Parse exec_section_arg];
        EM1 --> EM2{Section argument provided?};
        EM2 -- No --> B_Usage;
        EM2 -- Yes --> EM3[Execute specified section];
        EM3 --> E_Exit[End Execution];
    end

    B_Exit --> End;
    I_Exit --> End;
    E_Exit --> End;
```
