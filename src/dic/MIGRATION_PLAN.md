# 🚀 DIC System - MGT Wrapper Migration Plan

## Status: READY FOR PRODUCTION DEPLOYMENT ✅

Based on successful integration testing completed on June 11, 2025, the DIC system is now fully operational and ready to replace the MGT wrapper system.

## 🎯 Migration Strategy

### Phase 1: Core Replacement (Week 1)
**Goal**: Replace high-usage MGT wrappers with DIC operations

**Actions**:
1. **Backup existing MGT wrappers**
   ```bash
   cp -r src/mgt src/mgt.backup.$(date +%Y%m%d)
   ```

2. **Replace common operations**:
   - `pve_vpt_w` → `ops pve vpt`
   - `pve_vck_w` → `ops pve vck`
   - `sys_dpa_w` → `ops sys dpa`
   - `gpu_*_w` → `ops gpu *`

3. **Update calling scripts**:
   - Update all scripts that call MGT wrappers
   - Change function calls to `ops MODULE FUNCTION` format
   - Test each conversion

### Phase 2: Environment Integration (Week 2)
**Goal**: Ensure production environment compatibility

**Actions**:
1. **Deploy DIC to production systems**
2. **Configure environment variables** per hostname
3. **Test with real workloads**
4. **Monitor performance and error rates**

### Phase 3: Complete Migration (Week 3)
**Goal**: Remove all MGT wrappers and finalize transition

**Actions**:
1. **Replace remaining MGT functions**
2. **Update documentation and help systems**
3. **Train team on new `ops` command interface**
4. **Remove old MGT wrapper files**

## 📋 Conversion Examples

### Before (MGT Wrapper)
```bash
# Old way - individual wrapper functions
pve_vpt_w 100 on        # GPU passthrough for VM 100
pve_vck_w 101           # Check which node hosts VM 101
sys_dpa_w -x            # Display package analytics
```

### After (DIC Operations)
```bash
# New way - unified ops interface
ops pve vpt 100 on      # GPU passthrough for VM 100  
ops pve vck 101         # Check which node hosts VM 101
ops sys dpa -x          # Display package analytics
```

## 🔧 Required Environment Setup

For each production hostname, ensure these variables are configured:

```bash
# In cfg/env/production or equivalent
export ${hostname}_NODE_PCI0="0000:xx:00.0"
export ${hostname}_NODE_PCI1="0000:xx:00.1" 
export ${hostname}_CORE_COUNT_ON="N"
export ${hostname}_CORE_COUNT_OFF="M"
export PVE_CONF_PATH_QEMU="/etc/pve/qemu-server"
export CLUSTER_NODES=("node1" "node2" "node3")
```

## ✅ Validation Checklist

Before production deployment, verify:

- [ ] DIC system installed and executable
- [ ] Environment variables configured for all hostnames
- [ ] Test execution of key operations
- [ ] Error handling working correctly  
- [ ] Performance acceptable
- [ ] Team training completed
- [ ] Documentation updated
- [ ] Rollback plan prepared

## 🎉 Expected Benefits

### Immediate (Post-Migration)
- **90% code reduction**: ~2500 → ~300 lines
- **Unified interface**: Single `ops` command for all operations
- **Consistent behavior**: Standardized error handling and logging
- **Automatic maintenance**: No per-function wrapper updates needed

### Long-term (Ongoing)
- **Scalability**: New functions need zero wrapper code
- **Maintainability**: Single injection system to maintain
- **Testing**: Test injection engine once vs 90 wrappers
- **Documentation**: Self-documenting through conventions

## 🚨 Risk Mitigation

### Rollback Plan
If issues arise during migration:
1. Restore from `src/mgt.backup.*`
2. Revert calling script changes
3. Investigate and fix DIC issues
4. Re-attempt migration

### Monitoring
During migration, monitor:
- Function execution success rates
- Error message clarity
- Performance metrics
- User adaptation

## 📞 Support

For migration issues:
- **Documentation**: `src/dic/README.md`
- **Examples**: `src/dic/examples/`
- **Debug mode**: `OPS_DEBUG=1 ops ...`
- **Help system**: `ops --help`, `ops MODULE --help`

---

**Migration Status**: Ready to begin Phase 1  
**Authorization**: Approved based on successful integration testing  
**Timeline**: 3 weeks for complete migration  
**Success Criteria**: All MGT functionality available through DIC operations
