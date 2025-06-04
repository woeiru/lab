# Documentation Improvement Questions

Questions to enhance the documentation creation prompt for the Lab Environment Management System. Answer these to create a more targeted and effective documentation standard.

---

## 🎯 **Project-Specific Context**

### **1. Environment & Deployment Patterns**

**Q1.1**: What are the typical deployment scenarios?
- [ ] Single-node development
- [ ] Multi-node cluster 
- [ ] Development environment
- [ ] Production environment
- [ ] Testing/staging environment

**Answer**:


**Q1.2**: What do the environment configurations represent?
- `site1`: 
- `site1-dev`: 
- `site1-w2`: 

**Answer**:


**Q1.3**: What's the typical user journey from first clone to production deployment?

**Answer**:


### **2. Audience & Use Cases**

**Q2.1**: Who are your primary users and what are their main tasks?

**Infrastructure Teams**:
- Primary tasks:
- Pain points:
- Technical expertise level:

**Developers**:
- Primary tasks:
- Pain points:
- Technical expertise level:

**System Administrators**:
- Primary tasks:
- Pain points:
- Technical expertise level:

**End Users**:
- Primary tasks:
- Pain points:
- Technical expertise level:

**Answer**:


**Q2.2**: What are the most common pain points users encounter?

**Answer**:


**Q2.3**: What level of technical expertise should we assume for each audience?

**Answer**:


### **3. System Architecture Deep Dive**

**Q3.1**: What's the relationship and rationale between `lib/ops/` pure functions and `src/mgt/` wrappers?

**Answer**:


**Q3.2**: How does the configuration hierarchy work in practice? (base → env → node)

**Answer**:


**Q3.3**: What are the critical integration points between components?

**Answer**:


**Q3.4**: What happens during system initialization (`bin/ini`, `bin/orc`)?

**Answer**:


### **4. Documentation Workflow & Maintenance**

**Q4.1**: How often do you update documentation?

**Answer**:


**Q4.2**: What triggers documentation updates?
- [ ] Code changes
- [ ] New features
- [ ] User feedback
- [ ] Bug fixes
- [ ] Architecture changes
- [ ] Other: ____________

**Answer**:


**Q4.3**: Do you prefer generated docs or manual curation for certain components?

**Answer**:


**Q4.4**: What's your current biggest documentation pain point?

**Answer**:


### **5. Real-World Usage Patterns**

**Q5.1**: What are the top 10 most-used functions/scripts?

1. 
2. 
3. 
4. 
5. 
6. 
7. 
8. 
9. 
10. 

**Q5.2**: What are the most common error scenarios users encounter?

**Answer**:


**Q5.3**: What configuration mistakes do users make frequently?

**Answer**:


**Q5.4**: Which components require the most explanation/examples?

**Answer**:


### **6. Tool Integration & Automation**

**Q6.1**: How should AI-generated docs integrate with existing tools (`utl/doc/hub`, `aux_lad`, etc.)?

**Answer**:


**Q6.2**: Should the prompt account for auto-updating certain sections?

**Answer**:


**Q6.3**: Should the prompt suggest when to create README vs. comprehensive docs?

**Answer**:


### **7. Style & Voice Preferences**

**Q7.1**: What's your preferred level of technical detail?
- [ ] High-level conceptual
- [ ] Detailed technical
- [ ] Step-by-step procedural
- [ ] Mixed approach based on audience

**Answer**:


**Q7.2**: Do you prefer step-by-step procedures or conceptual explanations?

**Answer**:


**Q7.3**: How much context should be assumed vs. explained?

**Answer**:


**Q7.4**: Any specific terminology or conventions that must be used consistently?

**Answer**:


### **8. Quality & Validation**

**Q8.1**: How do you validate that documentation is accurate?

**Answer**:


**Q8.2**: What makes documentation "good enough" vs. "excellent" for your project?

**Answer**:


**Q8.3**: Are there examples of really good documentation in your project I should model after?

**Answer**:


**Q8.4**: Are there examples of poor documentation I should avoid?

**Answer**:


---

## 🔧 **Specific Technical Questions**

### **Configuration System**

**QC.1**: Can you walk through a typical configuration override scenario?

**Answer**:


**QC.2**: What's the difference between `cfg/core/` files and `cfg/env/` files?

**Answer**:


**QC.3**: How do users typically customize their environment?

**Answer**:


### **Function Organization**

**QF.1**: What's the decision process for putting something in `lib/` vs. `src/`?

**Answer**:


**QF.2**: How do wrapper functions (`-w` suffix) relate to their pure counterparts?

**Answer**:


**QF.3**: What are the testing patterns for each type of function?

**Answer**:


### **Deployment Workflows**

**QD.1**: What's a typical deployment workflow using `src/set/`?

**Answer**:


**QD.2**: How do the numbered scripts (c1, c2, etc.) relate to each other?

**Answer**:


**QD.3**: What's the difference between the various host configurations (h1, w2, etc.)?

**Answer**:


### **Error Handling & Debugging**

**QE.1**: What are the most common debugging scenarios?

**Answer**:


**QE.2**: How do users typically troubleshoot issues?

**Answer**:


**QE.3**: What information is most helpful in error messages?

**Answer**:


---

## 📊 **Meta Questions About Documentation Strategy**

**QM.1**: Should the prompt adapt based on the target directory? (different strategies for `lib/` vs. `src/` vs. `cfg/`)

**Answer**:


**QM.2**: How technical should README files be vs. comprehensive docs?

**Answer**:


**QM.3**: What's the balance between completeness and conciseness you prefer?

**Answer**:


**QM.4**: Should documentation include architecture decisions and rationale, or focus purely on usage?

**Answer**:


**QM.5**: What documentation automation would be most valuable?

**Answer**:


---

## 🎯 **Priority Questions**

**Which 5 areas from above would be most valuable to address first?**

1. 
2. 
3. 
4. 
5. 

**Any additional context or considerations not covered above?**

**Answer**:


---

*Complete these answers to create a highly targeted documentation prompt that understands your project's unique patterns and user needs.*
