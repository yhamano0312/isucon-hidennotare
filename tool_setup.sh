#!/bin/bash

# !!!!!!!!!要変更!!!!!!!!!!!!
ISU_GO_PATH=/home/isucon/local/go/bin/go # goバイナリのパス
REPO_PATH=/home/isucon/isuumo/webapp # リポジトリを管理するパス
REPO_NAME=isucon10 # リポジトリ名

# !!!!!!!!!!.ssh/configに設定したhost名を羅列すること!!!!!!!!!!!!!
for srv in "isu2" "isu3"
do
    echo 'starting tool setup for '${srv}

    # setting git
    echo "setting git"
    ssh ${srv} "git config --global user.name \"Yusuke Hamano\""
    ssh ${srv} "git config --global user.email \"yusuke.hamano@mixi.co.jp\""
    ssh ${srv} "echo -e \"Host github.com\n\tStrictHostKeyChecking no\n\" >> ~/.ssh/config"
    ssh ${srv} "git -C ${REPO_PATH} init"
    CHECK_REMOTE=`ssh ${srv} "git -C ${REPO_PATH} remote | wc -l"`
    if [ ${CHECK_REMOTE} -eq 0 ]; then
        ssh ${srv} "git -C ${REPO_PATH} remote add origin git@github.com:yhamano0312/${REPO_NAME}.git && git -C ${REPO_PATH} add *.gitignore && git -C ${REPO_PATH} commit -m \"add gitignore\" && git -C ${REPO_PATH} clean -df . && git -C ${REPO_PATH} pull origin master --allow-unrelated-histories --no-edit";
    else
        echo "skip git remote setting"
    fi

    # install alp
    echo "install alp"
    ssh ${srv} "sudo wget https://github.com/tkuchiki/alp/releases/download/v1.0.9/alp_linux_amd64.zip"
    ssh ${srv} "sudo unzip alp_linux_amd64.zip"
    ssh ${srv} "sudo install ./alp /usr/local/bin/alp"
    ssh ${srv} "sudo rm alp_linux_amd64.zip"
    ssh ${srv} "sudo rm alp"

    # install pt-query-digest
    echo "install pt-query-digest"
    ssh ${srv} "sudo curl -LO percona.com/get/pt-query-digest"
    ssh ${srv} "sudo chmod +x pt-query-digest"
    ssh ${srv} "sudo mv pt-query-digest /usr/local/bin"

    # setting pprof
    echo "setting pprof"
    ssh ${srv} "${ISU_GO_PATH} get -u github.com/google/pprof"
    ssh ${srv} "sudo apt install -y graphviz"

    echo 'finished tool setup for '${srv}

done
