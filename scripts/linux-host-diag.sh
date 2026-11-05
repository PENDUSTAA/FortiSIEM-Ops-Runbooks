#!/usr/bin/env bash
# Linux agent host diagnostics (read-only). Run as root on an affected RHEL host.
echo "== SELinux";  getenforce; ausearch -m avc,user_avc -ts this-week -i 2>/dev/null | tail -20
echo "== imfile denials (30d) count"; ausearch -m avc -ts this-month -c rsyslogd -i 2>/dev/null | grep -c imfile
echo "== auditd email actions"; grep -nE '^(space_left_action|admin_space_left_action|disk_full_action|disk_error_action)' /etc/audit/auditd.conf; ls -l /usr/lib/sendmail
echo "== audit enabled (2=immutable)"; auditctl -s | grep enabled
echo "== rsyslog local6/imfile/forward"; grep -rn -B2 -A3 'local6' /etc/rsyslog.conf /etc/rsyslog.d/; grep -rn -B1 -A6 imfile /etc/rsyslog.conf /etc/rsyslog.d/
echo "== rsyslog config check"; rsyslogd -N1; systemctl status rsyslog --no-pager | head -8
echo "== restarts"; systemctl show rsyslog auditd -p ActiveEnterTimestamp -p NRestarts
echo "== agent errors"; grep -E 'PH_UTIL_(DIR_OPEN|FILE_READ)_FAILURE' /opt/fortinet/fortisiem/linux-agent/log/phoenix.log | tail
echo "== rate limiting"; grep -iE 'rate-limit|lost [0-9]+ messages|suppressed' /var/log/messages | tail
echo "== /var/log usage"; df -h /var/log; du -xsh /var/log/* 2>/dev/null | sort -rh | head
echo "== messages growth KB/min"; a=$(stat -c %s /var/log/messages); sleep 60; b=$(stat -c %s /var/log/messages); echo "$(( (b-a)/1024 ))"
echo "== top writers"; tail -n 50000 /var/log/messages | awk '{print $5}' | sed 's/\[[0-9]*\]//' | sort | uniq -c | sort -rn | head
echo "== duplicate test"; logger -t duptest "hello $(date +%s)"; sleep 1; grep -c duptest /var/log/messages
