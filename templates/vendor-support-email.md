Subject: FortiSIEM Linux agent - repeated "Email option is specified but /usr/lib/sendmail doesn't seem executable" in syslog

Hello Support,

Case: [case number]   Agent: [agent version]   OS: [RHEL version]

The Linux agent runs ausearch internally and its stderr is logged to /var/log/messages
(tag fortisiem-linux-agent). On hosts without /usr/lib/sendmail this produces the warning
"Email option is specified but /usr/lib/sendmail doesn't seem executable." many times per hour.

We have removed the related FIM entry. Could you advise a supported workaround
(e.g. redirecting ausearch stderr or a setting to suppress it)? We prefer not to change auditd or install an MTA.

Thank you.
