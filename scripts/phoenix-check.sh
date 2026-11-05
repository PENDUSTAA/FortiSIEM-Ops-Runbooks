#!/usr/bin/env bash
# Run on Super / each Worker. Compare drop counter with your recorded baseline.
hostname
grep "stats:" /opt/phoenix/log/phoenix.log | tail -2 | grep -o "drop/bp=.*hwm([yn]"
echo "rejections in last 500 lines: $(tail -n 500 /opt/phoenix/log/phoenix.log | grep -ic 'congested\|reject upload')"
