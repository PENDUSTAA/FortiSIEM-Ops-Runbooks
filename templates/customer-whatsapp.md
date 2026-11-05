Hi, we noticed app log lines are duplicated in /var/log/messages (rsyslog local6 rule).
We plan to stop that extra copy to reduce noise. It should not affect UEBA on the Linux agent.
Does anyone use those app entries from /var/log/messages? If not, we'll test on one server first: [server names].
