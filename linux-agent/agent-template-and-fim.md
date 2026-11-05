# Linux agent: Monitor Template, FIM, and how logs really flow

## Agent facts (7.4.x)
- Agent sends events to the collector over HTTPS (443, `/linuxupload`). Required packages: `audit`, `rsyslog`, `logrotate`.
- Agent runs `ausearch` internally from `lib64/libphLinuxAgentUtils.so`; stderr is not redirected, so auditd.conf warnings land in `/var/log/messages` tagged `fortisiem-linux-agent[PID]`. Nothing in `config/` or `bin/` calls it (searched with `grep -rl ausearch`), so it cannot be fixed at script level.
- Linux UEBA analytics use `LINUX_PROCESS_EXEC`, `Generic_Unix_System_Shutdown`, `Generic_Unix_Successful_SSH_Login`. No custom app logs.

## Template tabs (what we found)
- **Syslog**: standard facilities only (kern, user, mail, daemon, auth, syslog, authpriv, ftp, cron), local0-local7 unticked.
- **Log File**: empty. So app logs did NOT come through the agent template; the path was the host's own rsyslog (imfile -> local6 -> forward).
- **FIM**: only `/var/log/secure` (`All;Push Files`). Redundant with authpriv syslog and noisy.

## Cautions
- FIM/template changes can restart `auditd` and `rsyslog` -> looks like intermittent log loss. Do them in a maintenance window, one host first. Check `systemctl show rsyslog auditd -p ActiveEnterTimestamp -p NRestarts`.
- Audit immutable mode (`auditctl -s | grep enabled` = 2): rule changes (and new FIM watches) need a reboot; `service auditd reload` fails harmlessly. Use `kill -HUP $(pidof auditd)` for `auditd.conf` changes.
- If a host matches more than one template, check the host-to-template association.

## Keep /var/log from filling (documented agent guidance)
```
# /etc/logrotate.d/messages-size (example)
/var/log/messages {
    size 50M
    rotate 10
    compress
    copytruncate
    missingok
}
```
Also set `max_log_file` / `num_logs` in `auditd.conf`. Verify how often logrotate really runs (cron.hourly or timer).

## Noise sources to know
- `key="delete"` audit rule logs renames; an app rotating `file.TRC.N -> N+1` generates ~100 audit lines per rotation (benign).
- Every `ausearch`/`ethtool` run by the agent is itself audited.
- setroubleshoot writes one very long line per denial into `messages`; fix the denial rather than removing setroubleshoot.
- Recurring `sshd kex_exchange_identification ... Connection reset` from monitor IPs (e.g. 192.0.2.30): confirm they are yours.
- A single `IPTABLES-OUT Default Drop` to the collector on 443: confirm the firewall allows agent -> collector 443.
