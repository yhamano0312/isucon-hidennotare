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
### ssh
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

### 各種ミドルウェアの確認
以下の実行結果をissueに貼っておく
```
nginx -v
go version
mysql --version
systemctl list-units --type=service
```

### GitHubリポジトリ接続用のキーを作成
- `ssh-keygen -t rsa`で鍵を作成する
- 作成した秘密鍵を他サーバにも移動させる
- 権限は600にする

### GitHubリポジトリ作成と公開鍵登録
- リポジトリをプライベートで作成する
- 作成した公開鍵をdeploy keyとしてリポジトリに登録する。その時にwrite権限のチェックボックスも入れる

### 各種コードをGitHubにpushする
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

### newrelicインストール
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
  - name: nginx-error-log
    file: /var/log/nginx/error.log
```

- sudo systemctl restart newrelic-infra
- systemctl status newrelic-infra.service でサービス起動しているか確認

### tool_setup.shの各種設定を変更して実行する

### nginx,mysqlの初期設定

#### nginx設定
```
# /etc/nginx/nginx.conf
## httpディレクティブ
### アクセスログ設定
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

### nginx高速化設定
sendfile        on;
tcp_nopush     on;

### APとのkeepalive設定
upstream backend {
        server localhost:1323;
        keepalive 32;
}

## serverディレクティブ
### gzip設定
    gzip on;
    gzip_types text/css text/javascript application/javascript application/xjavascript application/json;
    gzip_min_length 1k;

### APとのkeepalive設定
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    keepalive_requests 10000;
    #### proxy_passは書き換える
    proxy_pass http://backend;
```
設定したら再起動する
sudo systemctl restart nginx

#### mysqlのスロークエリログ設定
```
# /etc/mysql/conf.d/my.cnf
[mysqld]
slow_query_log=1
slow_query_log_file=/var/log/mysql/mysql-slow.log
long_query_time=0
```

#### mysqlのバイナリログを無効化
```
# /etc/mysql/mysql.conf.d/mysqld.cnf
innodb_flush_log_at_trx_commit=2
disable-log-bin=1
```
設定したら再起動する
sudo systemctl restart mysql

#### 各種設定ファイルをgit管理にする
git管理ディレクトリに設定ファイルをcpして管理する。ディレクトリ名は`middle-setting`にしておく
修正したconfファイル以外で管理しておいた方が良いもの
- ~/env.sh
```
git add --all
git commit -m "add middleware conf"
git push origin master
```

### apからdbへのコネクション設定
```
# main.go

db.SetConnMaxLifetime(10 * time.Second)
db.SetMaxIdleConns(512)
db.SetMaxOpenConns(512)
```

### deploy.sh,analyze.shの各種設定を変更して動作することを確認する

### ベンチマークを実行する 


## pprof導入
[pprof導入](https://medium.com/eureka-engineering/go%E8%A8%80%E8%AA%9E%E3%81%AE%E3%83%97%E3%83%AD%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AA%E3%83%B3%E3%82%B0%E3%83%84%E3%83%BC%E3%83%AB-pprof%E3%81%AEweb-ui%E3%81%8C%E3%82%81%E3%81%A1%E3%82%83%E3%81%8F%E3%81%A1%E3%82%83%E4%BE%BF%E5%88%A9%E3%81%AA%E3%81%AE%E3%81%A7%E7%B4%B9%E4%BB%8B%E3%81%99%E3%82%8B-6a34a489c9ee)

tool_setup.shでライブラリ等は導入しているので
サーバ上で`pprof -http=0.0.0.0:8080 http://localhost:6060/debug/pprof/profile?seconds=90`と叩いておけばローカルから8080で繋がる

## tips
- 間違いとかでgit rebaseでコミットをまとめたりするとpull時にconflictしてめんどいので、rebaseで綺麗にしようとしない
- スキーマファイルがあるので見て把握すること！
- スキーマが複雑な場合はtblsでER図を作ってみる
  - https://zenn.dev/lightkun/articles/6caf17872b6521
- 修正いれたら空コミットでベンチ結果を保存しておくと良いぞ。issueにも分析結果を貼っておこう
  - `{"pass":true,"score":1108,"messages":[{"text":"GET /api/estate/:id: リクエストに失敗しました (タイムアウトしました)","count":8},{"text":"POST /api/estate/nazotte: リクエストに失敗しました (タイムアウトしました)","count":20}],"reason":"OK","language":"go"}`の後に複数行のベンチ結果を貼り付けて最終行にEOMを入れる
- ミドルウェアの設定ファイルもgit管理のリポジトリに新しくディレクトリを切って保存しておくと良さそう
  - nginx
  - mysql
  - go.service
- APログはgolangだとSaaSに送るのにも時間がかかってしまうので`/var/log/syslog`で確認するようにする
- new relicのlogsクエリでは以下のようにやるとsyslogの200以外のログを出してくれる
  - `filePath:"/var/log/syslog" isucondition -"\"status\":200"`
- EXPLAINで調べる時は実際に実数値が指定されたクエリを叩いて確認する
- nginxでの正規表現記法
  - https://blog.mitsuto.com/nginx-useragent-deny
  - https://scrapbox.io/ohbarye/Nginx%E3%81%A7%E6%AD%A3%E8%A6%8F%E8%A1%A8%E7%8F%BE%E3%82%92%E4%BD%BF%E3%81%A3%E3%81%A6bot%E3%82%92%E5%BC%BE%E3%81%8F
- var でmapを初期値で定義するとにるぽが起きるためmakeで初期化すること
  - `var c_chairs = make(map[string][]Chair)`
- 全文検索を行いたい場合はFULLTEXT INDEXの作成とクエリ修正を行う
  - https://zenn.dev/hiroakey/articles/9f68ad249af20c
    - 日本語検索ならINDEXにngramをつける
    - SELECTにはBOOLEAN MODEを指定するで良さそう

## 後片付けチェックリスト
- [] nginxのロク出力をなくす
  - ログが出なくなっていることを確認する。
- [] mysqlのログ出力をなくす
  - ログが出なくなっていることを確認する。
- [] appで頻繁に出されるログ出力をなくす
  - ログが出なくなっていることを確認する。logLevel自体を消すとdebugログが出力されてしまうことがあるので、logLevelをOFFにするのも検討する
    - https://github.com/yhamano0312/isucon10/commit/3bb1ec43a65f0d08459fb2344321419dd9703f8e
    - https://github.com/Nagarei/isucon11-qualify-test/commit/d5b1378dbe1d5be4dd349e5a312b803307928a5c
- [] newrelic infrastracture agentのsystemdを止める
- [] 最後にベンチマーク実行→再起動→ブラウザからwebアプリ触る→ベンチマーク実行をやる
## チェックポイント
### 全般
- 大量にログ出力している部分を削る
  - debugログ
- 各systemdのLimitNOFILE,LimitNPROCの上限を1006500に上げておく
  - mysqlを上げたければ`/etc/systemd/system/mysql.service`に記載する
  - 1度しか変更しないのでgit管理しなくても良さそう
  - https://qiita.com/ochiba/items/88acd3c764bb271ad483
- 最初から複数台のサーバが用意されているが、負荷リクエストは1台に対してしか行かないので、負荷分散する必要がある
  - https://isucon.net/archives/56082639.html
    - CPU リソースが足りない問題を複数台を使うことで改善
  - 分散させるのは競技の後半にして、indexとかの修正を先にやる
  - 場合によってはDBサーバを分割させる
    - https://github.com/Nagarei/isucon11-qualify-test/commit/207ace7d999b0216b5626c248ac87efb22cbd47e
    - https://github.com/Nagarei/isucon11-qualify-test/commit/fb2f1b56e2eca481ebc6816e7726e83c8509d1aa
  - 分割させたら使ってないサービスの常時起動は切っておく
- `ベンチマーク実行時にアプリケーションに書き込まれたデータは再起動後にも取得できること`とレギュレーションにあるので再起動した後にブラウザから動作確認すること
  - https://blog.recruit.co.jp/rls/2020-09-25-isucon10-qualify/
  - サーバを分けると再起動時にAPからのDB接続で失敗してAPが立ち上がらないことがあるので、systemdにserviceの最大再起動回数を指定しておく
    - https://matsuu.hatenablog.com/entry/2020/09/13/131145
- ISUCONのあれこれの内容ができているか確認する
  - https://zenn.dev/daisuzz/scraps/87498988adc162
### nginx
- 画像ファイル等の静的ファイルがnginxから返すようになっているか確認する
  - nginxから入ってない場合はAP側でファイルに保存するようにして、nginxから`try_files`設定で読むようにする(ISUCON本参照)
- cacheを使って良い静的ファイルを配信するlocationディレクティブには`expires 1d`を設定する
  - cacheがうまく効いていない(304で返っていない)ようなら`add_header Cache-Control: public`をつけてみる
    - https://egapool.hatenablog.com/entry/2020/04/04/141404
  - nginxを複数台にしていると同じファイルでも更新時刻が異なってLast-Modifiedが異なってしまい上手くcacheが効かないのでrsyncで同期等させる(ISUCON本参照)
- `client request body is buffered to a temporary file`が発生している場合は`client_body_buffer_size`を調整する
- 
### Go
- DBへのクエリを最小限にするためにキャッシュしてよいものはキャッシュする
  - https://github.com/yhamano0312/isucon10/commit/264ecebe84726f9a4131d20f311e83754083d8d2
- 画像データ等がDBに含まれている場合は必要な時以外は取得しないようにカラムを指定してSELECTする
- ADMIN PREPAREが多数実行されている場合はsql.Open時にinterpolateParamsをtrueにしてみる
  - `db,err:=sql.Open("mysql","isuconp:@tcp(127.0.0.1:3306)/isuconp?interpolateParams=true")`
- `exec.Command`でOSコマンドを大量に呼び出している場合はGo実装に変更できないか確認する
- http.Clientを使っている場合はtransport設定等を見直す
- 外部サービス呼び出し等で並行処理できる場合はwgとgoroutinで制御する
  - https://github.com/takonomura/isucon9-qualify/compare/c74a0569985e5b768fcc01138100ab453b95f456..c2cc325925067290a2852ce34f7cb52909425d7a
-  
### DB
- WHERE句に指定する条件がさまざまで全ての条件にindexを貼るのが現実的でない場合はORDER BYで指定した項目だけにindexを貼ってみる
- 自動採番のidをPKとしている場合に既存のカラムの複合キーでPKにならないか
- スキーマの変更は直接やらずにsqlファイルに記載する
- 降順のORDER BY は  MySQL 5.7 では単純に index を貼っても効かない
  - MySQL の generated columns を使って 負の値を持った popularity を作ってそこに入れたりする
  - MySQL 8系にupdateするでも良いがbinary_logが有効化されたりと遅くなるので無効化する
- indexはwhereとorder byで使われているカラムを指定するが、カーディナリティ等の関係でindexが使われない可能性もあるので、クエリ側にforce indexを指定するか時間がかかっている処理に集中したindexを貼る
  - https://zenn.dev/progfay/articles/isucon10-qualify#level-0-(1-~-299)
- EXPLAINのextaraでUsing TemporaryやUsing Filesortのものは無くすようにする
  - https://qiita.com/nikadon/items/2f66b447ed6d3b26d78e
- Generated Columnはデータの持ち方が2種類あるので、indexが効かないとかがあればGeo系のカラム等の場合はSTOREDにしてみる
  - https://qiita.com/naka_kyon/items/f3e19ab7a6275ab394bf#%E3%83%87%E3%83%BC%E3%82%BF%E3%81%AE%E6%8C%81%E3%81%A1%E6%96%B9
- Geo系のindexはSPATIAL INDEXを使う
- DBでcommitでCPUが使われている場合は大量にINSERTが走っているのでバルクインサートにする
  - https://github.com/Nagarei/isucon11-qualify-test/commit/324ad3eeac56d545cca192c6e18567cf2b5e231a
  - sqlx.Tx.NamedExecでバルクインサートする場合はsqlxのバージョンを1.21以上にする必要があるため注意
    - https://github.com/jmoiron/sqlx/issues/519#issuecomment-704060007
- 複合indexの順番は気を付ける
  - https://nishinatoshiharu.com/overview-multicolumn-indexes/
- SQLで大部分を取得してから条件判定で省く場合はSQLの時点で絞りこむようにカラム追加とかをする

### 参考になるサイト集
- [ISUCON9 予選を全体1位で突破しました](https://www.takono.io/posts/2019/09/isucon/)
- [ISUCON11 予選問題実践攻略法](https://isucon.net/archives/56082639.html)