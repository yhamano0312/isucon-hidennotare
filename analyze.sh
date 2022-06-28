#!/bin/bash

# !!!!!!!!!.ssh/configに設定した分析させたいサーバを指定!!!!!!!!!
NGINX_TARGET_SERVER="isu1"
DB_TARGET_SERVER="isu1"

# !!!!!!!!!ディレクトリ名修正!!!!!!!!!
OUTPUT_FILE="./analyze_output/isucon10/analyze.`date \"+%Y%m%d_%H%M%S\"`"

# alp で解析
echo
echo ":: ACCESS LOG       ====>" | tee -a ${OUTPUT_FILE}
ssh ${NGINX_TARGET_SERVER} "sudo cat /var/log/nginx/access.log | alp json -m \"/api/isu/[0-9a-zA-Z]+,/api/condition/[0-9a-zA-Z]+,/isu/[0-9a-zA-Z]+\" --sort sum -r" | tee -a ${OUTPUT_FILE}
#ssh ${NGINX_TARGET_SERVER} "sudo cat /var/log/nginx/access.log | alp ltsv -m "/api/schedules/[0-9a-zA-Z]+" --sort avg -r" | tee -a ${OUTPUT_FILE}

#  mysqldumpslowで解析
echo
echo ":: SLOWQUERY(mysqldumpslow) LOG       ====>" | tee -a ${OUTPUT_FILE}
ssh ${DB_TARGET_SERVER} "sudo mysqldumpslow /var/log/mysql/mysql-slow.log" | tee -a ${OUTPUT_FILE}

# pt-query-digestで分析
echo
echo ":: SLOWQUERY(pt-query-digest) LOG       ====>" | tee -a ${OUTPUT_FILE}
ssh ${DB_TARGET_SERVER} "sudo pt-query-digest /var/log/mysql/mysql-slow.log" | tee -a ${OUTPUT_FILE}
