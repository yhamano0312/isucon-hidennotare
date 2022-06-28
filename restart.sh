#!/bin/bash

# !!!!!!!!!要変更!!!!!!!!!!!!
BINARY_FILE_NAME=isuumo # 実行バイナリの名前

# !!!!!!!!!.ssh/configに設定した再起動させたいサーバを指定!!!!!!!!!
NGINX_TARGET_SERVER="isu1"
APP_TARGET_SERVER="isu1"
DB_TARGET_SERVER="isu1"

# 各種ログの削除
echo ":: CLEAR LOGS       ====>"
ssh ${NGINX_TARGET_SERVER} "sudo truncate -s 0 -c /var/log/nginx/access.log"
ssh ${DB_TARGET_SERVER} "sudo truncate -s 0 -c /var/log/mysql/mysql-slow.log"

# 各種サービスの再起動
echo
echo ":: RESTART SERVICES ====>"
ssh ${DB_TARGET_SERVER} "sudo systemctl restart mysql"
ssh ${APP_TARGET_SERVER} "sudo systemctl restart ${BINARY_FILE_NAME}.go.service"
ssh ${NGINX_TARGET_SERVER} "sudo systemctl restart nginx"

# # pprof実行
# echo
# echo ":: START pprof ====>"
# ssh ${APP_TARGET_SERVER} "pprof -http=0.0.0.0:8080 http://localhost:6060/debug/pprof/profile?seconds=90 ＆"
