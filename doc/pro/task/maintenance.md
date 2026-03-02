Read and apply doc/pro/task/RULES.md first.

Perform a weekly doc/pro maintenance pass.

Do this in order:
1. Run bash doc/pro/check-workflow.sh; fix structural/naming issues only
   (checker failures are safe to fix autonomously)
2. List active items; flag stale ones (Updated older than 7 days)
3. For each stale item, recommend: keep active, complete, or dismiss
4. Review queue ordering; suggest top 3 execution candidates
5. Verify completed items are in completed/<topic>/
6. Re-run bash doc/pro/check-workflow.sh

Constraints:
- Fix only structural issues (checker failures) autonomously
- Do not move files between workflow states without my approval
- Present state-transition recommendations as a list for me to approve

Report:
- Checker results (before and after)
- Active summary with staleness flags
- Recommendation per stale item
- Queue priority ranking
- Structural fixes applied (if any)
