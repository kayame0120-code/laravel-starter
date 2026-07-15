# laravel-starter

Fly.io（Tokyo/nrt）+ Fly Postgres 前提の Laravel 12 量産テンプレート。
CC（Claude Code）自律運用ルール同梱（`CLAUDE.md` / `.claude/settings.json`）。

## 構成

| 要素 | 内容 |
|---|---|
| Laravel | 12 / PHP 8.2 |
| ローカルDB | SQLite（スケルトン既定） |
| 本番DB | Fly Postgres（`DATABASE_URL` 接続） |
| デプロイ | Fly.io（`ubuntu:22.04` + Ondrej PPA Dockerfile） |
| CC運用 | `CLAUDE.md`（恒久ルール）+ `docs/spec.md`（アプリ固有・毎回書く） |

## 新アプリの始め方

### 1. リポジトリ生成
GitHub の **Use this template** ボタンから新リポジトリを作成 → clone。

### 2. ローカルセットアップ
```bash
composer install
cp .env.example .env
php artisan key:generate
touch database/database.sqlite
php artisan migrate
php artisan serve   # http://127.0.0.1:8000/up が 200 なら成功
```

### 3. アプリ固有の準備
- `docs/spec.md` を書く（CCに渡す仕様。CLAUDE.md は編集しない）
- `fly.toml` の `app = 'CHANGE-ME'` を新アプリ名に書き換える

## 本番デプロイ（初回・人間が実行）

```bash
# 1. Flyアプリ作成（fly.tomlのapp名と一致させる）
fly apps create <アプリ名>

# 2. Postgres作成 → アタッチ（DATABASE_URLが自動でsecretに入る）
fly postgres create --name <アプリ名>-db --region nrt
fly postgres attach <アプリ名>-db --app <アプリ名>

# 3. APP_KEYをsecretに設定
fly secrets set APP_KEY=$(php artisan key:generate --show) --app <アプリ名>

# 4. デプロイ（release_command がマイグレーションを自動実行する）
fly deploy

# 5. マイグレーション実行の確認
fly logs --app <アプリ名> | grep -i migrate
# → 「Nothing to migrate.」または実行済みマイグレーション名が出れば成功
```

## 2回目以降のデプロイ

```bash
fly deploy
# マイグレーションは release_command が自動実行する（手動実行は不要）
```

## 運用規約（要点。詳細は CLAUDE.md）

- `migrate:fresh` の本番実行は禁止
- DBのENUM型は禁止（string + アプリ側バリデーション）
- SQLite/PostgreSQL で挙動が割れる書き方（DB固有関数・生SQL依存）は禁止
- 本番コマンド（fly deploy / seed）は人間が実行する。マイグレーションは release_command 経由で deploy 内で自動実行される
