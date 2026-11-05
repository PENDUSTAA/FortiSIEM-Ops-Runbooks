# Fortinet / vendor references

Links only, with short notes in our own words (no vendor text copied). Versions differ from our 7.4.1; confirm against your release.

## Linux agent
- Linux Agent Installation Guide 7.4.1: https://docs.fortinet.com/document/fortisiem/7.4.1/linux-agent-installation-guide/201446/fortisiem-linux-agent
  - Did not state where the agent sources logs; subsections on `/var/log/messages` / syslog were not readable when checked.
- Linux Agent Installation Guide 7.5.0: https://docs.fortinet.com/document/fortisiem/7.5.0/linux-agent-installation-guide
  - Lists `audit`, `rsyslog`, `logrotate` as required packages; has a section on rotating `/var/log/messages`.
- Linux Agent Installation Guide 6.3.2: https://docs.fortinet.com/document/fortisiem/6.3.2/linux-agent-installation-guide
  - Warns auditd output can fill `/var/log/messages`; sample logrotate (size-based, `copytruncate`, compressed). Older release, may differ.
- Linux Agent Installation Guide 5.2.8 (older): https://docs.fortinet.com:443/document/fortisiem/5.2.8/linux-agent-installation-guide/201446/
- Configuring Linux Agent (7.0.0 online help): https://help.fortinet.com/fsiem/7-0-0/Online-Help/HTML5_Help/Configuring_Linux_Agent.htm
- Community tip, preventing auditd/rsyslog restarts when the Linux agent is installed (FIM changes can restart them): https://community.fortinet.com/fortisiem-34/technical-tip-how-to-prevent-auditd-and-rsyslog-service-restart-while-linux-agent-has-been-installed-on-a-host-184660

## UEBA
- FortiSIEM 7.2.2 User Guide, UEBA: https://docs.fortinet.com/document/fortisiem/7.2.2/user-guide/777852
  - Linux UEBA analytics run on regular agent logs: unusual process creation (`LINUX_PROCESS_EXEC`), unusual shutdown (`Generic_Unix_System_Shutdown`), unusual SSH logon (`Generic_Unix_Successful_SSH_Login`).
- FortiSIEM 7.3.4 User Guide page seen in search: https://docs.fortinet.com/document/fortisiem/7.3.4/user-guide/544088

## Elasticsearch event storage
- Setting up Elasticsearch for FortiSIEM Event Storage (7.1.4): https://docs.fortinet.com:443/document/fortisiem/7.1.4/elasticsearch-storage-guide
- Same guide (6.5.0): https://docs.fortinet.com/document/fortisiem/6.5.0/elasticsearch-storage-guide
- Native Elasticsearch retention threshold (6.3.0 online help): https://help.fortinet.com/fsiem/6-3-0/Online-Help/HTML5_Help/Database_Settings_Elasticsearch_Retention.htm
- Not found for 7.4.1 specifically: check the 7.4 Elasticsearch storage guide on docs.fortinet.com for hot/warm and retention behavior.

## External systems (Linux server syslog)
- Linux Server (external systems configuration guide 6.7.8): https://docs.fortinet.com/document/fortisiem/6.7.8/external-systems-configuration-guide/742954

## Elastic (upstream)
- Cluster-level shard allocation and routing, disk-based allocation watermarks, ILM, snapshot/restore and the cluster reroute API in the Elasticsearch 7.17 reference (elastic.co/guide/en/elasticsearch/reference/7.17).
