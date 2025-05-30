# Three-Letter Directory Structure Decision Guide

A comprehensive guide for deciding what goes where in the three-letter directory structure.

## bin/ - Binaries and Executables

**Purpose**: Contains executable scripts and programs that are part of your application ecosystem.

**Put here**:
- Application starter scripts
- Deployment automation scripts
- Database maintenance scripts
- Backup utilities
- Service control scripts (start/stop/restart)
- Build scripts
- Health check scripts

**Don't put here**:
- Source code that generates executables
- Configuration files
- One-off scripts that aren't part of regular operations
- Development tools that aren't part of the application

## cfg/ - Configuration

**Purpose**: Contains configuration files that change between environments or deployments.

**Put here**:
- Environment-specific configurations (dev/staging/prod)
- API keys and secrets (encrypted)
- Feature flags
- Database connection strings
- Service endpoints
- Security certificates
- Environment variables files

**Don't put here**:
- Application code that handles configuration
- Default/template configurations (use res/)
- Hard-coded constants (use src/)
- Test configurations (use separate test directory)

## dat/ - Data

**Purpose**: Contains static/reference data that's part of the application.

**Put here**:
- Lookup tables
- Reference data (country codes, currency rates)
- Database seed data
- Data schemas and definitions
- Initial state data
- Test datasets
- Data migration scripts

**Don't put here**:
- User-generated data (use var/)
- Temporary processing data (use tmp/)
- Configuration files (use cfg/)
- Dynamic application data

## doc/ - Documentation

**Purpose**: Contains all project documentation.

**Put here**:
- API documentation
- Architecture diagrams
- Setup instructions
- User guides
- Development guidelines
- License information
- Change logs
- Design documents

**Don't put here**:
- Generated documentation (use var/)
- Temporary documentation drafts (use tmp/)
- Code comments (keep with source)
- Environment-specific instructions (use cfg/)

## lib/ - Libraries

**Purpose**: Contains reusable code that could potentially be used in other projects.

**Put here**:
- Utility functions
- Helper classes
- Framework-like code
- Database abstraction layers
- Generic validation functions
- Common data structures
- Shared interfaces

**Don't put here**:
- Application-specific business logic (use src/)
- Environment-specific code (use src/)
- Generated code (use var/)
- Third-party libraries (use a package manager)

## log/ - Logs

**Purpose**: Contains application logs and audit trails.

**Put here**:
- Application logs
- Error logs
- Access logs
- Audit trails
- Performance logs
- Debug logs
- Security logs

**Don't put here**:
- Log processing scripts (use bin/)
- Log configuration (use cfg/)
- Historical logs (archive elsewhere)
- Test logs (use tmp/)

## res/ - Resources

**Purpose**: Contains static resources used by the application.

**Put here**:
- HTML templates
- Email templates
- Static images
- CSS/JavaScript files
- Localization files
- Default configurations
- Font files
- Static assets

**Don't put here**:
- User-uploaded files (use var/)
- Generated resources (use var/)
- Temporary resources (use tmp/)
- Environment-specific resources (use cfg/)

## src/ - Source Code

**Purpose**: Contains the main application source code.

**Put here**:
- Application core code
- Business logic
- Domain models
- API endpoints
- Service implementations
- Main entry points
- Application-specific implementations

**Don't put here**:
- Reusable utilities (use lib/)
- Generated code (use var/)
- Configuration (use cfg/)
- Static resources (use res/)

## tmp/ - Temporary Files

**Purpose**: Contains files that are temporarily needed and can be safely deleted.

**Put here**:
- Upload buffers
- Processing queues
- Temporary caches
- Session files
- Temporary exports
- Report generation workspace
- Build artifacts

**Don't put here**:
- Important user data (use var/)
- Logs (use log/)
- Anything that needs to persist
- Shared resources

## var/ - Variable Data

**Purpose**: Contains data that changes during application runtime and needs to persist.

**Put here**:
- User uploads
- Generated files
- Application state
- Persistent cache
- Generated reports
- Modified resources
- Runtime data

**Don't put here**:
- Source code (use src/)
- Static resources (use res/)
- Configuration (use cfg/)
- Temporary files (use tmp/)

## General Guidelines

1. **Version Control**:
   - Include in VCS: src/, lib/, res/, cfg/ (non-sensitive), doc/, bin/
   - Exclude from VCS: tmp/, var/, log/, sensitive configs

2. **Permissions**:
   - Restrict access to cfg/ (especially secrets)
   - Make bin/ executables executable
   - Protect log/ from unauthorized access
   - Make tmp/ writable by application

3. **Backup Considerations**:
   - Regular backup: var/, dat/
   - No backup needed: tmp/, log/ (unless audit required)
   - Config backup: cfg/ (secure storage)

4. **Cleanup Policies**:
   - tmp/: Regular cleanup safe
   - log/: Rotation policy needed
   - var/: Cleanup with caution
   - dat/: Preserve unless explicitly updated

5. **Deployment Considerations**:
   - cfg/: Different per environment
   - var/: May need data migration
   - tmp/: Clean between deployments
   - log/: May need archival

6. **Security Considerations**:
   - cfg/: Encrypt sensitive data
   - var/: Scan uploaded files
   - tmp/: Clear sensitive data
   - log/: Sanitize sensitive information

Remember: These are guidelines, not strict rules. Adapt them to your project's specific needs while maintaining the spirit of clear organization and separation of concerns.
