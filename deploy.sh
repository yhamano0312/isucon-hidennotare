#!/bin/bash -eu

# !!!!!!!!!要変更!!!!!!!!!!!!
REPO_PATH=/home/isucon/webapp # レポジトリをcloneしたパス
ISU_GO_PATH=/home/isucon/local/go/bin/go # goバイナリのパス
# !!!!!!!!!!!ipを/etc/hostsに設定すること!!!!!!!!!!!!!
APP_TARGET_SERVER="isu1"
NGINX_TARGET_SERVER="isu1"
DB_TARGET_SERVER="isu2"


echo 'RUNNING DEPLOY ISUCON SERVERS'

echo 'STARTING'
for srv in ${APP_TARGET_SERVER} ${NGINX_TARGET_SERVER} ${DB_TARGET_SERVER}
do
    ssh ${srv} "git -C ${REPO_PATH} pull origin master"
done

echo 'DEPLOY GO'
# # !!!!!!!!!!!元々の実行ファイル名とサービス名を指定!!!!!!!!!!!!!
ssh ${APP_TARGET_SERVER} "cd ${REPO_PATH}/go && ${ISU_GO_PATH} build -o isucondition"
ssh ${APP_TARGET_SERVER} "cp ${REPO_PATH}/middle-setting/env.sh ."
ssh ${APP_TARGET_SERVER} "sudo systemctl restart isucondition.go.service"

echo 'DEPLOY nginx'
# # !!!!!!!!!!!元々の設定ファイルパスとサービス名を指定!!!!!!!!!!!!!
ssh ${NGINX_TARGET_SERVER} "sudo cp ${REPO_PATH}/middle-setting/nginx/nginx.conf /etc/nginx"
ssh ${NGINX_TARGET_SERVER} "sudo systemctl restart nginx"

echo 'DEPLOY mysql'
# # !!!!!!!!!!!元々の設定ファイルパスとサービス名を指定!!!!!!!!!!!!!
ssh ${DB_TARGET_SERVER} "sudo cp ${REPO_PATH}/middle-setting/mysql/my.cnf /etc/mysql/conf.d"
ssh ${DB_TARGET_SERVER} "sudo cp ${REPO_PATH}/middle-setting/mysql/50-server.cnf /etc/mysql/mariadb.conf.d/"
ssh ${DB_TARGET_SERVER} "sudo systemctl restart mysql"

echo 'FINISHED'