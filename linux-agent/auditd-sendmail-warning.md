# "Email option is specified but /usr/lib/sendmail doesn't seem executable"

## Symptom
/var/log/messages flooded with this line (tag `fortisiem-linux-agent`) on RHEL hosts.

## Cause
`ausearch` prints it when `/etc/audit/auditd.conf` has an `email` action but no sendmail binary exists.
The FortiSIEM Linux agent runs `ausearch` internally and logs its stderr.

## Fix (OS level)
```bash
cp -p /etc/audit/auditd.conf /etc/audit/auditd.conf.bak
sed -i -E 's/^(space_left_action|admin_space_left_action)[[:space:]]*=[[:space:]]*(email|EMAIL)/\1 = syslog/' /etc/audit/auditd.conf
grep -nE '^(space_left_action|admin_space_left_action|disk_full_action|disk_error_action)' /etc/audit/auditd.conf
ausearch -ts today 2>&1 >/dev/null | head -2    # warning should be gone
kill -HUP $(pidof auditd)                       # not `service auditd reload` if audit is immutable (-e 2)
```
Alternatives: stub `/usr/lib/sendmail` (hides email silently), a FortiSIEM drop rule, or ask the vendor for an agent-side fix.

## Related
- `key="delete"` audit rule logs *renames* (log rotation) - benign noise.
- Audit immutable mode (`-e 2`) blocks rule reload, not `auditd.conf` reads.
