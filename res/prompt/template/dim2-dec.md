# Second Dimension Domain Decision Template

## Purpose
To guide systematic decision-making about where to place components within the second dimension domain structure of a three-letter directory system, ensuring consistent and logical organization of system components.

## Required Inputs
- {{component_name}} - Name of the component being organized
- {{component_purpose}} - Primary purpose/function of the component
- {{component_dependencies}} - List of other components this component interacts with
- {{component_lifecycle_stage}} - Development stage of the component (e.g., core, experimental, testing)

## Optional Parameters
- {{security_requirements}} - Any specific security considerations
- {{performance_requirements}} - Performance considerations
- {{scalability_needs}} - Expected scaling requirements
- {{team_ownership}} - Team responsible for the component

## Context
The second dimension domain organization provides functional groupings that cut across the primary three-letter structure. Each domain serves a specific purpose and follows established patterns for component organization.

## Instructions
1. Analyze the component's primary purpose against these domain types:

   - core/ : Foundation systems and essential functionality
   - depl/ : Deployment and installation operations
   - util/ : Helper tools and support functions
   - admin/: System administration tasks
   - api/  : Interface-related components
   - mod/  : Extensible and pluggable components
   - test/ : Testing-related components
   - dev/  : Development-specific tools

2. Consider the following factors:
   - Component's fundamental purpose
   - Integration requirements
   - Lifecycle stage
   - Maintenance patterns
   - Team organization
   - Security boundaries
   - Performance implications

3. Evaluate cross-domain communication needs
4. Assess domain hierarchy implications
5. Consider future scaling requirements

## Constraints
- Each component should primarily belong to one domain
- Domain placement should minimize cross-domain dependencies
- Must maintain clear domain boundaries
- Must follow established naming conventions
- Must consider security implications of domain placement

## Expected Output Format
```
Domain Decision:
Selected Domain: {{selected_domain}}
Subdomain: {{selected_subdomain}}
Full Path: {{domain_path}}

Justification:
{{detailed_reasoning}}

Implementation Considerations:
{{list_of_considerations}}

Migration Steps (if applicable):
{{migration_steps}}
```

## Examples
Input Example:
```
{
  "component_name": "AuthService",
  "component_purpose": "Handle user authentication and authorization",
  "component_dependencies": ["UserDB", "SessionManager", "SecurityLogger"],
  "component_lifecycle_stage": "core",
  "security_requirements": "high"
}
```

Expected Output:
```
Domain Decision:
Selected Domain: core/
Subdomain: auth/
Full Path: core/auth/service

Justification:
Authentication is a fundamental system service required by multiple 
components. Its critical nature and security requirements make it 
suitable for core/ rather than mod/ or api/.

Implementation Considerations:
- Implement as core service with strict access controls
- Maintain high-security standards
- Ensure scalable design
- Provide clear integration points

Migration Steps:
1. Create core/auth directory structure
2. Move authentication components
3. Update dependency references
4. Verify security configurations
```

## Validation Rules
1. Selected domain must be one of the defined domain types
2. Path must follow naming conventions
3. Justification must address:
   - Primary purpose alignment
   - Security considerations
   - Integration impacts
   - Maintenance implications

## Error Handling
Common issues to check:
1. Domain conflict resolution:
   - If component could fit multiple domains, use these priorities:
     a. Security criticality (prefer core/)
     b. Fundamental nature (prefer core/)
     c. Interface nature (prefer api/)
     d. Extensibility needs (prefer mod/)

2. Invalid domain selection:
   - Verify against domain purposes
   - Check for naming conflicts
   - Validate against security requirements

3. Cross-domain dependencies:
   - Identify circular dependencies
   - Evaluate communication patterns
   - Check security boundaries
