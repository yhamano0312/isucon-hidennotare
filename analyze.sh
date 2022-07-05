#!/bin/bash

# !!!!!!!!!.ssh/configに設定した分析させたいサーバを指定!!!!!!!!!
NGINX_TARGET_SERVER="isu1"
DB_TARGET_SERVER="isu1"
#DB_TARGET_SERVER="isu2 isu3"

# !!!!!!!!!ディレクトリ名修正!!!!!!!!!
OUTPUT_FILE="./analyze_output/isucon-9-q/analyze.`date \"+%Y%m%d_%H%M%S\"`"

# alp で解析
echo
for srv in ${NGINX_TARGET_SERVER}
do
    echo ":: ACCESS LOG(${srv})       ====>" | tee -a ${OUTPUT_FILE}
    ssh ${srv} "sudo cat /var/log/nginx/access.log | alp json --sort sum -r" | tee -a ${OUTPUT_FILE}
    #ssh ${srv} "sudo cat /var/log/nginx/access.log | alp json -m \"/api/estate/[0-9]+,/api/chair/[0-9]+,/api/recommended_estate/[0-9]+,/api/chair/buy/[0-9]+,/api/estate/req_doc/[0-9]+,/images/estate/[0-9a-zA-z]+,/_next/static/chunks/[0-9a-zA-z]+\" --sort sum -r" | tee -a ${OUTPUT_FILE}
    #ssh ${srv} "sudo cat /var/log/nginx/access.log | alp ltsv -m "/api/schedules/[0-9a-zA-Z]+" --sort avg -r" | tee -a ${OUTPUT_FILE}
done

#  mysqldumpslowで解析
echo
for srv in ${DB_TARGET_SERVER}
do
    echo ":: SLOWQUERY(mysqldumpslow) LOG(${srv})       ====>" | tee -a ${OUTPUT_FILE}
    ssh ${srv} "sudo mysqldumpslow -g SELECT -s t -t 20 /var/log/mysql/mysql-slow.log" | tee -a ${OUTPUT_FILE}
    # ssh ${srv} "sudo mysqldumpslow -s t -t 20 /var/log/mysql/mysql-slow.log" | tee -a ${OUTPUT_FILE}

# pt-query-digestで分析
    echo
    echo ":: SLOWQUERY(pt-query-digest) LOG(${srv})       ====>" | tee -a ${OUTPUT_FILE}
    ssh ${srv} "sudo pt-query-digest --limit 5 /var/log/mysql/mysql-slow.log" | tee -a ${OUTPUT_FILE}
done