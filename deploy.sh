#!/bin/bash -eu

# !!!!!!!!!要変更!!!!!!!!!!!!
REPO_PATH=/home/isucon/isuumo/webapp # レポジトリをcloneしたパス
ISU_GO_PATH=/home/isucon/local/go/bin/go # goバイナリのパス
BINARY_FILE_NAME=isuumo # 実行バイナリの名前
NGINX_CONF_PATH=/etc/nginx # nginx.confのパス
NGINX_ISUUMO_CONF_PATH=/etc/nginx/sites-available # isuumo.confのパス
MYSQL_MYCNF_PATH=/etc/mysql/conf.d # my.cnfのパス
MYSQL_MYSQLDCNF_PATH=/etc/mysql/mysql.conf.d # mysqld.cnfのパス

# !!!!!!!!!!!ipを/etc/hostsに設定すること!!!!!!!!!!!!!
APP_TARGET_SERVER="isu1"
NGINX_TARGET_SERVER="isu1"
DB_TARGET_SERVER="isu2 isu3"

echo 'RUNNING DEPLOY ISUCON SERVERS'

echo 'STARTING'
for srv in ${APP_TARGET_SERVER} ${NGINX_TARGET_SERVER} ${DB_TARGET_SERVER}
do
    ssh ${srv} "git -C ${REPO_PATH} pull origin master"
    ssh ${srv} "cp ${REPO_PATH}/middle-setting/env.sh ."
done

echo 'DEPLOY GO'
for srv in ${APP_TARGET_SERVER}
do
    ssh ${srv} "cd ${REPO_PATH}/go && ${ISU_GO_PATH} build -o ${BINARY_FILE_NAME}"
    ssh ${srv} "sudo systemctl restart ${BINARY_FILE_NAME}.go.service"
done

echo 'DEPLOY nginx'
for srv in ${NGINX_TARGET_SERVER}
do
    ssh ${srv} "sudo cp ${REPO_PATH}/middle-setting/nginx.conf ${NGINX_CONF_PATH}"
    ssh ${srv} "sudo cp ${REPO_PATH}/middle-setting/isuumo.conf ${NGINX_ISUUMO_CONF_PATH}"
    ssh ${srv} "sudo systemctl restart nginx"
done

echo 'DEPLOY mysql'
for srv in ${DB_TARGET_SERVER}
do
    ssh ${srv} "sudo cp ${REPO_PATH}/middle-setting/my.cnf ${MYSQL_MYCNF_PATH}"
    ssh ${srv} "sudo cp ${REPO_PATH}/middle-setting/mysqld.cnf ${MYSQL_MYSQLDCNF_PATH}"
    ssh ${srv} "${REPO_PATH}/mysql/db/init.sh"
    ssh ${srv} "sudo systemctl restart mysql"
done

# 各種ログの削除
echo ":: CLEAR LOGS       ====>"
for srv in ${NGINX_TARGET_SERVER}
do
    ssh ${srv} "sudo truncate -s 0 -c /var/log/nginx/access.log"
done

for srv in ${DB_TARGET_SERVER}
do
    ssh ${srv} "sudo truncate -s 0 -c /var/log/mysql/mysql-slow.log"
done

# # pprof実行
# echo
# echo ":: START pprof ====>"
# ssh ${APP_TARGET_SERVER} "pprof -http=0.0.0.0:8080 http://localhost:6060/debug/pprof/profile?seconds=90 ＆"

echo 'FINISHED'