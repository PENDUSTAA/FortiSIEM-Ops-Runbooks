Hi, your application logs go through syslog (local6) and are also copied into /var/log/messages.
UEBA on Linux is based on process execution, SSH login and shutdown logs, not these application logs,
so we do not expect any impact on UEBA if we stop copying them into /var/log/messages.
This avoids duplicate entries and keeps that file smaller.

Could you confirm that no team or tool of yours reads these application entries from /var/log/messages?
If not, we will test on one server first ([server names]), check UEBA and log collection still work, then apply to the rest.
It is easy to reverse.

Note: confirm first (rsyslog forward vs imfile vs file read) that ingestion does not depend on /var/log/messages. See linux-agent/rsyslog-local6-notes.md.
