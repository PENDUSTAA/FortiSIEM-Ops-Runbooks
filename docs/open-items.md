# Open items

- [ ] Snapshot repository + SLM policy, or replicas (no backup confirmed).
- [ ] Confirm ILM retention (90 d vs 120 d) before first deletions.
- [ ] Extend smallest hot node disk / rebalance big shards (low watermark 75%).
- [ ] Check Workers' ES endpoint list; add a second bulk endpoint.
- [ ] Script B on every VM; Hyper-V host review (`infra/hyperv-storage-checklist.md`).
- [ ] Alerts: write queue, rejections, `hwm=y`, drop counter, disk > 70%.
- [ ] Remove odd cluster settings (`unsafe-bootstrap`, `search.max_buckets`) after review.
- [ ] Remove dead collectors; fix Hot Node Age display mismatch.
- [ ] auditd.conf `email` -> `syslog` fleet-wide; await vendor reply on the sendmail warning.
- [ ] Apply `logging_syslogd_list_non_security_dirs` boolean on the DR app host, verify imfile AVC count is 0 and app logs arrive.
- [ ] Decide on `/var/log/secure` FIM entry (redundant with authpriv).
- [ ] Restore or fix local6 forwarding if the edit broke it; verify with `logger` test.
