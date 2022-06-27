#!/bin/bash

# !!!!!!!!!.ssh/configに設定した再起動させたいサーバを指定!!!!!!!!!
NGINX_TARGET_SERVER="isu1"
APP_TARGET_SERVER="isu1"
DB_TARGET_SERVER="isu2"

# 各種ログの削除
echo ":: CLEAR LOGS       ====>"
ssh ${NGINX_TARGET_SERVER} "sudo truncate -s 0 -c /var/log/nginx/access.log"
ssh ${DB_TARGET_SERVER} "sudo truncate -s 0 -c /var/log/mysql/mysql-slow.log"

# 各種サービスの再起動
echo
echo ":: RESTART SERVICES ====>"
ssh ${DB_TARGET_SERVER} "sudo systemctl restart mysql"
# !!!!!!!!使用する言語を指定!!!!!!!!!!
ssh ${APP_TARGET_SERVER} "sudo systemctl restart isucondition.go"
ssh ${NGINX_TARGET_SERVER} "sudo systemctl restart nginx"

# # pprof実行
# echo
# echo ":: START pprof ====>"
# ssh ${APP_TARGET_SERVER} "pprof -http=0.0.0.0:8080 http://localhost:6060/debug/pprof/profile?seconds=90 ＆"
