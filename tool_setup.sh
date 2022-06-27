#!/bin/bash

# 手動でやるやつらなので各サーバにsshして手動実行する
## newRelic
#### あまり使わなそうなので入れなくても良さそう
### infrastracture agent(シェル経由で実行すると上手く入らないので)

## integrationは何も入れない
## `https://one.newrelic.com/marketplace?state=8f7c77a8-30cd-8fdc-a321-6bc59d796d28`に出力されるURLで実行する
## NEW_RELIC_API_KEYはUser Typeを指定する
# curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && sudo NEW_RELIC_API_KEY=xxxxxxxxxxx NEW_RELIC_ACCOUNT_ID=xxxxxxx /usr/local/bin/newrelic install

# /etc/newrelic-infra.ymlにenable_process_metrics: trueを設定

# /etc/newrelic-infra/logging.d にfile.ymlを以下の内容で作成
```
logs:
  - name: syslog
    file: /var/log/syslog
  - name: mysql-error-log
    file: /var/log/mysql/error.log
```

# sudo systemctl restart newrelic-infra
# systemctl status newrelic-infra.service でサービス起動しているか確認

# !!!!!!!!!要変更!!!!!!!!!!!!
ISU_GO_PATH=/home/isucon/local/go/bin/go # goバイナリのパス
REPO_PATH=/home/isucon/webapp # リポジトリを管理するパス

# !!!!!!!!!!.ssh/configに設定したhost名を羅列すること!!!!!!!!!!!!!
for srv in "isu2"
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
    # !!!!!!!!!!リポジトリ名を変更!!!!!!!!!!!!!!!
        ssh ${srv} "git -C ${REPO_PATH} remote add origin git@github.com:yhamano0312/isucon11.git && git -C ${REPO_PATH} add *.gitignore && git -C ${REPO_PATH} commit -m \"add gitignore\" && git -C ${REPO_PATH} clean -df . && git -C ${REPO_PATH} pull origin master --allow-unrelated-histories --no-edit";
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
