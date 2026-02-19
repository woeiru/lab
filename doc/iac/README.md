# Infrastructure as Code Documentation

## Navigation
- [Repository Root](../../README.md)
- [Documentation Hub](../README.md)

## Purpose
`doc/iac/` documents deployment workflows, environment hierarchy, and infrastructure runbooks.

## Child Docs
- [doc/iac/deployment.md](./deployment.md)
- [doc/iac/environment.md](./environment.md)
- [doc/iac/qdevice-runbook-deep-dive.md](./qdevice-runbook-deep-dive.md)

## Common Tasks
- Start with deployment guide for set-based rollout workflows.
- Use environment guide for hierarchy and override behavior.
- Use qdevice runbook only for quorum-device setup/recovery scenarios.

## Troubleshooting
- If deployment instructions fail, validate active environment files under `cfg/env/` and DIC flow in `src/dic/README.md`.

## Related Docs
- [Configuration Root](../../cfg/README.md)
- [Documentation Hub](../README.md)
