#!/bin/bash -eu

# !!!!!!!!!要変更!!!!!!!!!!!!
REPO_PATH=/home/isucon/isuumo/webapp # レポジトリをcloneしたパス
ISU_GO_PATH=/home/isucon/local/go/bin/go # goバイナリのパス
BINARY_FILE_NAME=isuumo # 実行バイナリの名前

# !!!!!!!!!!!ipを/etc/hostsに設定すること!!!!!!!!!!!!!
APP_TARGET_SERVER="isu1"
NGINX_TARGET_SERVER="isu1"
DB_TARGET_SERVER="isu1"

echo 'RUNNING DEPLOY ISUCON SERVERS'

echo 'STARTING'
for srv in ${APP_TARGET_SERVER} ${NGINX_TARGET_SERVER} ${DB_TARGET_SERVER}
do
    ssh ${srv} "git -C ${REPO_PATH} pull origin master"
done

echo 'DEPLOY GO'
ssh ${APP_TARGET_SERVER} "cd ${REPO_PATH}/go && ${ISU_GO_PATH} build -o ${BINARY_FILE_NAME}"
# # !!!!!!!!!!!必要であればgit管理にして設定する!!!!!!!!!!!!!
# ssh ${APP_TARGET_SERVER} "cp ${REPO_PATH}/middle-setting/env.sh ."
ssh ${APP_TARGET_SERVER} "sudo systemctl restart ${BINARY_FILE_NAME}.go.service"

echo 'DEPLOY nginx'
ssh ${NGINX_TARGET_SERVER} "sudo cp ${REPO_PATH}/middle-setting/nginx.conf /etc/nginx"
ssh ${NGINX_TARGET_SERVER} "sudo systemctl restart nginx"

echo 'DEPLOY mysql'
ssh ${DB_TARGET_SERVER} "sudo cp ${REPO_PATH}/middle-setting/my.cnf /etc/mysql/conf.d"
# ssh ${DB_TARGET_SERVER} "sudo cp ${REPO_PATH}/middle-setting/mysql/50-server.cnf /etc/mysql/mariadb.conf.d/"
ssh ${DB_TARGET_SERVER} "sudo systemctl restart mysql"

echo 'FINISHED'