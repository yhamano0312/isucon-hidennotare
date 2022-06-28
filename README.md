# isucon 秘伝のタレ集
ISUCONに参加するに辺り参考になる資料やコマンドをまとめておく

## 運営提供資料
[事前講習](https://speakerdeck.com/rosylilly/isucon12-shi-qian-jiang-xi)
[ハンズオン](https://cdn.discordapp.com/attachments/983875667382927471/984067555171909682/b3e0e29a24ffb23f.pdf)

## 過去開催の解説
[ISUCON11 予選問題実践攻略法](https://isucon.net/archives/56082639.html)

## newrelic
[ISUCON10予選問題にNew Relic Infrastructureを入れてみる](https://newrelic.com/jp/blog/how-to-relic/install-newrelic-infrastructure-for-isucon10-qualify)

[インフラストラクチャエージェントの導入](https://docs.newrelic.com/jp/docs/infrastructure/install-infrastructure-agent/linux-installation/tarball-assisted-install-infrastructure-agent-linux/)

## 競技開始直後にやること
1. ssh
sshできることを確認する
```
$ ssh isucon@133.152.5.xxx
```
そして~/.ssh/configに

```
Host isu1
  HostName 133.152.5.xxx
  User isucon
```

を記載すると
```
$ ssh isu1
```
で入れる。
作成されたサーバは登録しておく。

2. GitHubリポジトリ接続用のキーを作成
- `ssh-keygen -t rsa`で鍵を作成する
- 作成した秘密鍵を他サーバにも移動させる
- 権限は600にする

3. GitHubリポジトリ作成と公開鍵登録
- リポジトリをプライベートで作成する
- 作成した公開鍵をdeploy keyとしてリポジトリに登録する。その時にwrite権限のチェックボックスも入れる

4. 各種コードをGitHubにpushする
```
cd ~/webapp
git init
git config --global user.email "yusuke.hamano@mixi.co.jp"
git config --global user.name "Yusuke Hamano"
git add --all
git commit -m "first commit"
# sshのURLになってること確認!!!!!!!!!!!!
git remote add origin git@github.com:yhamano0312/isucon12.git
git push origin master
```

5. newrelicインストール
- 以下のURLから出力されるワンライナーを叩く
  - https://one.newrelic.com/launcher/nr1-core.explorer?pane=eyJuZXJkbGV0SWQiOiJucjEtY29yZS5saXN0aW5nIn0=&cards[0]=eyJuZXJkbGV0SWQiOiJucjEtaW5zdGFsbC1uZXdyZWxpYy5ucjEtaW5zdGFsbC1uZXdyZWxpYyIsImFjdGl2ZUNvbXBvbmVudCI6IlZUU09FbnZpcm9ubWVudCIsInBhdGgiOiJndWlkZWQifQ==

- /etc/newrelic-infra.ymlにenable_process_metrics: trueを設定

- /etc/newrelic-infra/logging.d にfile.ymlを以下の内容で作成

```
logs:
  - name: syslog
    file: /var/log/syslog
  - name: mysql-error-log
    file: /var/log/mysql/error.log
```

- sudo systemctl restart newrelic-infra
- systemctl status newrelic-infra.service でサービス起動しているか確認

1. tool_setup.shの各種設定を変更して実行する

2. nginx,mysqlのログ出力を有効化する

### nginxアクセスログ設定
既存設定を踏襲してlog_formatを以下にする
```
# /etc/nginx/nginx.conf
    log_format json escape=json '{'
    '"time":"$time_iso8601",'
    '"host":"$remote_addr",'
    '"port":"$remote_port",'
    '"method":"$request_method",'
    '"uri":"$request_uri",'
    '"status":"$status",'
    '"body_bytes":"$body_bytes_sent",'
    '"referer":"$http_referer",'
    '"ua":"$http_user_agent",'
    '"request_time":"$request_time",'
    '"response_time":"$upstream_response_time"'
    '}';

    access_log  /var/log/nginx/access.log  json;

```
設定したら再起動する
sudo systemctl restart nginx

### mysqlのスロークエリログ設定
```
# /etc/mysql/conf.d/my.cnf
[mysqld]
slow_query_log=1
slow_query_log_file=/var/log/mysql/mysql-slow.log
long_query_time=0
```
設定したら再起動する
sudo systemctl restart mysql

### 各種設定ファイルをgit管理にする
git管理ディレクトリに設定ファイルをcpして管理する。ディレクトリ名は`middle-setting`にしておく
```
git add --all
git commit -m "add middleware conf"
git push origin master
```

8. deploy.sh,restart.sh,analyze.shの各種設定を変更して動作することを確認する

9. ベンチマークを実行する 


## pprof導入
[pprof導入](https://medium.com/eureka-engineering/go%E8%A8%80%E8%AA%9E%E3%81%AE%E3%83%97%E3%83%AD%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AA%E3%83%B3%E3%82%B0%E3%83%84%E3%83%BC%E3%83%AB-pprof%E3%81%AEweb-ui%E3%81%8C%E3%82%81%E3%81%A1%E3%82%83%E3%81%8F%E3%81%A1%E3%82%83%E4%BE%BF%E5%88%A9%E3%81%AA%E3%81%AE%E3%81%A7%E7%B4%B9%E4%BB%8B%E3%81%99%E3%82%8B-6a34a489c9ee)

tool_setup.shでライブラリ等は導入しているので
サーバ上で`pprof -http=0.0.0.0:8080 http://localhost:6060/debug/pprof/profile?seconds=90`と叩いておけばローカルから8080で繋がる

## tips
- 間違いとかでgit rebaseでコミットをまとめたりするとpull時にconflictしてめんどいので、rebaseで綺麗にしようとしない
- スキーマファイルがあるので見て把握すること！
- 修正いれたら空コミットでベンチ結果を保存しておくと良いぞ。issueにも分析結果を貼っておこう
  - `{"pass":true,"score":1108,"messages":[{"text":"GET /api/estate/:id: リクエストに失敗しました (タイムアウトしました)","count":8},{"text":"POST /api/estate/nazotte: リクエストに失敗しました (タイムアウトしました)","count":20}],"reason":"OK","language":"go"}`の後に複数行のベンチ結果を貼り付けて最終行にEOMを入れる
- ミドルウェアの設定ファイルもgit管理のリポジトリに新しくディレクトリを切って保存しておくと良さそう
  - nginx
  - mysql
  - go.service
- APログはgolangだとSaaSに送るのにも時間がかかってしまうので`/var/log/syslog`で確認するようにする
- new relicのlogsクエリでは以下のようにやるとsyslogの200以外のログを出してくれる
  - `filePath:"/var/log/syslog" isucondition -"\"status\":200"`

## 後片付けチェックリスト
- [] nginxのロク出力をなくす

- [] mysqlのログ出力をなくす

- [] appで頻繁に出されるログ出力をなくす

- [] newrelic infrastracture agentのsystemdを止める

## チェックポイント
- フルスキャンになっているクエリにはindexを貼る
- 自動採番のidをPKとしている場合に既存のカラムの複合キーでPKにならないか
- スキーマの変更は直接やらずにsqlファイルに記載するなりやる
- 画像ファイル等の静的ファイルは極力nginxから返すようにしてcacheを入れる
- DBのバイナリログは出力しないようにする
- DBでcommitでCPUが使われている場合は大量にINSERTが走っているのでバルクインサートにする
- SQLで大部分を取得してから条件判定で省く場合はSQLの時点で絞りこむようにカラム追加とかをする
- 大量にログ出力している部分を削る
- 各systemdのLimitNOFILE,LimitNPROCの上限を1006500に上げておく
  - mysqlを上げたければ`/etc/systemd/system/mysql.service`に記載する
  - 1度しか変更しないのでgit管理しなくても良さそう
  - https://qiita.com/ochiba/items/88acd3c764bb271ad483
- 最初から複数台のサーバが用意されているが、負荷リクエストは1台に対してしか行かないので、負荷分散する必要がある
  - 分散させるのは競技の後半にして、indexとかの修正を先にやる
  - 場合によってはDBサーバを分割させる
  - 分割させたら使ってないサービスの常時起動は切っておく
- ISUCONのあれこれの内容ができているか確認する
  - https://zenn.dev/daisuzz/scraps/87498988adc162