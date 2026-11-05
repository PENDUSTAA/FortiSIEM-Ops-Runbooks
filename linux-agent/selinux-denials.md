# SELinux denials seen with FortiSIEM agent / rsyslog

## 1. Agent helper tools writing to agent tmp
- `ethtool` (ifconfig_t), `logrotate` (logrotate_t) denied write on `/opt/fortinet/fortisiem/linux-agent/tmp/*` (label `usr_t`).
- Fix: relabel the tmp directory (e.g. `semanage fcontext` + `restorecon -Rv`) so confined tools can write.

## 2. rsyslog imfile cannot list an application directory
- `comm=in:imfile`, `exe=/usr/sbin/rsyslogd`, `scontext=syslogd_t`, target dir `/appdata` (`default_t`), EACCES every ~10 s (imfile poll).
- Impact: new/rotated files are not discovered, so app logs become intermittent.
- Fix:
```bash
getsebool logging_syslogd_list_non_security_dirs
setsebool -P logging_syslogd_list_non_security_dirs on
sleep 30; ausearch -m avc -ts recent -i 2>/dev/null | grep -c imfile   # expect 0
```
- Then check for follow-on denials on the files themselves. Cleaner long-term: label the log directory `var_log_t`.
- setroubleshoot writes very long lines to /var/log/messages per denial; fixing the denial removes the noise.
