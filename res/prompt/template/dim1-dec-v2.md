# Three-Letter Directory Structure Recommendation Template

## Purpose
To provide structured recommendations for organizing files and directories within a three-letter directory structure system, ensuring consistent organization across projects while supporting domain-driven organization patterns.

## Required Inputs
- {{project_type}} - Type of project (e.g., web application, CLI tool, library)
- {{primary_programming_language}} - Main programming language used
- {{file_types}} - List of file types that need to be organized
- {{domain_structure}} - List of business/functional domains if using domain-driven organization

## Optional Parameters
- {{security_requirements}} - Any specific security considerations
- {{deployment_environment}} - Target deployment environment(s)
- {{backup_requirements}} - Specific backup needs
- {{retention_policies}} - Any data retention requirements

## Context
This template assists in determining the appropriate location for different types of files within a standardized three-letter directory structure. The structure consists of twelve main directories: bin/, cfg/, dat/, doc/, lib/, log/, pro/, res/, src/, tmp/, and var/. Each directory serves a specific purpose and has clear guidelines for what should and shouldn't be stored there.

## Instructions
1. Review the provided file types and project requirements
2. For each file type or component, evaluate against the following criteria:
   - Is it executable? → Consider bin/
   - Is it configuration? → Consider cfg/
   - Is it reference data? → Consider dat/
   - Is it documentation? → Consider doc/
   - Is it reusable code? → Consider lib/
   - Is it logging data? → Consider log/
   - Is it domain-specific project code? → Consider pro/
   - Is it a static resource? → Consider res/
   - Is it core application code? → Consider src/
   - Is it temporary? → Consider tmp/
   - Is it variable runtime data? → Consider var/

## Constraints
- Each file should be placed in exactly one directory
- Files must follow the defined purpose of each directory
- Security-sensitive files must follow appropriate protection measures
- Version control inclusion/exclusion must be considered for each directory
- Domain-specific code should maintain vertical organization within pro/

## Expected Output Format
For each directory, provide:
1. List of recommended files/components to include
2. List of files/components to exclude
3. Specific handling instructions (permissions, backup, security)

## Examples
Input Example:
```
{
  "project_type": "Web Application",
  "primary_programming_language": "Python",
  "file_types": [
    "Python source files",
    "Configuration YAML",
    "User uploads",
    "Log files",
    "Frontend assets",
    "Domain-specific business logic"
  ],
  "domain_structure": [
    "customer-management",
    "order-processing",
    "inventory"
  ],
  "security_requirements": "GDPR compliance",
  "deployment_environment": ["development", "production"],
  "backup_requirements": "Daily backups required",
  "retention_policies": "Logs retained for 90 days"
}
```

Expected Output:
```
Directory Recommendations:

pro/
- Include: Domain-specific business logic, feature-complete modules
- Structure:
  customer-management/
    - models/
    - services/
    - interfaces/
  order-processing/
    - workflows/
    - validators/
    - handlers/
  inventory/
    - tracking/
    - forecasting/
    - reporting/
- Exclude: Generic utilities, shared libraries
- Handling: Domain-driven organization, version controlled, team ownership

src/
- Include: Core application code, shared utilities
- Exclude: Domain-specific business logic, configurations
- Handling: Version controlled, code review required

cfg/
- Include: YAML configuration files
- Exclude: Source code, static assets
- Handling: Encrypt sensitive data, environment-specific configs

var/
- Include: User uploads
- Exclude: Application code, configurations
- Handling: Regular backups, GDPR compliance measures

log/
- Include: Application logs
- Exclude: Source code, user data
- Handling: 90-day retention, rotation policy

res/
- Include: Frontend assets
- Exclude: User uploads, configuration
- Handling: Version controlled, CDN deployment
```

## Validation Rules
1. Ensure no file type is assigned to multiple directories
2. Verify security-sensitive files have appropriate protection measures
3. Confirm backup requirements are met for critical directories
4. Validate version control recommendations against best practices
5. Verify domain separation in pro/ directory follows domain-driven principles

## Error Handling
- If a file type doesn't clearly fit any directory:
  1. Evaluate against secondary characteristics
  2. Consider project-specific requirements
  3. Document reasoning for placement decision
  4. Consider creating a new subdirectory if necessary

## Notes
- Directory structure may need adaptation based on:
  - Project size and complexity
  - Team size and organization
  - Deployment requirements
  - Security considerations
  - Regulatory compliance needs
  - Domain boundaries and relationships

### Special Considerations for pro/ Directory
- Follows domain-first architectural principles
- Maintains vertical organization within domains
- Supports feature-complete modules
- Enables clear team ownership
- Facilitates independent deployment
- Preserves domain cohesion
- Supports contextual hierarchy
- Enables semantic organization
