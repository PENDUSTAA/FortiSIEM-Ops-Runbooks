# Custom app logs via rsyslog (local6)

- Default RHEL rule `*.info;mail.none;authpriv.none;cron.none  /var/log/messages` already matches local6.
- An extra explicit `local6.* /var/log/messages` rule therefore duplicates lines.
- Removing a rule line can break a following `&` continuation rule (e.g. a forward action). Check with `rsyslogd -N1`.
- Before stopping the local6 -> messages copy, confirm ingestion does **not** depend on it:
```bash
grep -rn -B2 -A3 'local6' /etc/rsyslog.conf /etc/rsyslog.d/
grep -rn -B1 -A6 imfile /etc/rsyslog.conf /etc/rsyslog.d/
rsyslogd -N1 && systemctl status rsyslog
logger -p local6.info "dup-test $(date +%s)"     # check how many copies land
```
- Standard syslog target example: `192.0.2.20:514/UDP`, facility local7.
- Agent Monitor Template tabs (Syslog / Log File / FIM) did not carry these app logs in this case; the path was host rsyslog.
