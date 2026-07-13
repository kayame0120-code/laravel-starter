# deploy_runbook.md — テンプレート

> アプリ固有のrunbookを作るときにコピーして使う。
> 人間が上から順に実行するだけの状態に仕上げてから提出する。

## 0. ローカル検証完了（実施済み）

V1〜V3（+ 該当時V4）の検証ログを貼る。

## 1. バックアップ取得＋サイズ確認

**pg_dump はアプリイメージに存在しない場合がある。**
Fly Postgres VM（`<app名>-db`）から実行すること。

```bash
# アプリVMからDATABASE_URLを取得
fly ssh console -C "sh -c 'echo \$DATABASE_URL'" --app <app名>

# Postgres VMでpg_dump実行
fly ssh console -C "sh -c 'pg_dump \"<DATABASE_URL>\" --format=custom --file=/tmp/backup.dump'" --app <app名>-db

# サイズ確認（サーバー側）
fly ssh console -C "ls -lh /tmp/backup.dump" --app <app名>-db

# ローカルにダウンロード
fly sftp get /tmp/backup.dump ./backup.dump --app <app名>-db

# サイズ確認（ローカル側）
ls -lh ./backup.dump
```

## 2. fly.toml の release_command（確認）

```toml
[deploy]
  release_command = 'php /var/www/html/artisan migrate --force'
```

## 3. デプロイ

```bash
fly deploy
```

## 4. 動作確認

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://<app名>.fly.dev/up
```

## 5. ロールバック（万一の場合）

### 主経路: pg_restore

pg_restore はスキーマごとバックアップ時点に戻す。マイグレーションの down() に依存しない。

```bash
# 1. アプリを停止（リストア中のDB書込みを防ぐ）
fly scale count 0 --app <app名>

# 2. 旧イメージに戻す
fly releases
fly deploy --image <1つ前のimage>

# 3. ダンプをPostgres VMにアップロードしてリストア
fly sftp shell --app <app名>-db
put backup.dump /tmp/backup.dump
exit
fly ssh console -C "sh -c 'pg_restore --clean --if-exists -d \"<DATABASE_URL>\" /tmp/backup.dump'" --app <app名>-db

# 4. 復元確認
fly ssh console -C "php /var/www/html/artisan tinker --execute=\"echo DB::table('<確認テーブル>')->count();\"" --app <app名>

# 5. 後片付け
fly ssh console -C "rm /tmp/backup.dump" --app <app名>-db
```
