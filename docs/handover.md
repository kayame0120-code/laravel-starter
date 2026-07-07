# laravel-starter 引き継ぎ書

- version: v1.0
- updated: 2026-07-07
- sources: laravel-starterテンプレ構築セッション（2026-07-07・Fable5）

## 確定事項（再調査・再議論禁止。変更するなら人間に確認）
- テンプレ: github.com/kayame0120-code/laravel-starter（Template repository化済み）
- Laravel 12 / PHP 8.2。**11以下はEOL + composer security advisoryブロックで選択不可**
- 構成: ローカルSQLite / 本番Fly Postgres（`DATABASE_URL`一本。.envにpgsql設定は書かない）
- fly.tomlは `/up` ヘルスチェック付き（コールドスタート502防止・ASYLUM実証済み）
- CLAUDE.md（恒久ルール）+ .claude/settings.json（deny付き）同梱。
  **アプリ固有は docs/spec.md へ。CLAUDE.md は編集しない**
- 新アプリ立ち上げはスニペット①〜⑨が正。`fly launch` は使わない（`fly apps create`）

## 検証済み / 未検証の境界
- 検証済み: Use this template → clone → ローカル起動（煙テスト合格 2026-07-07。
  composer install / migrate / serve / welcomeページ表示まで確認）
- **未検証: Fly実デプロイ（スニペット⑤〜⑨）**。このテンプレからの実走はゼロ。
  初回デプロイで詰まったら evidence-first-ops（ログ取得→原因→合意→解決。推測修正禁止）。

### 本書を読んでいるモデルへの更新指示
初デプロイの成功（本番URLで /up が200）を確認したセッションでは、
そのセッション内で以下を実行してから終了すること。次回に持ち越さない:
1. 本書の改訂版を成果物として出力する
   （「未検証」→「実証済み（実行日付き）」/ version +0.1 / sources に当該セッションを追記）
2. デプロイスニペット⑤〜⑨の「実証済み」格上げ版も併せて出力する
3. 人間に docs/handover.md の差し替えとコミットを促す

## 環境メモ（片倉のローカル固有）
- ローカルのデフォルトPHPは 8.2 に変更済み（Ondrej PPA・8.1と共存）
- 学校課題等で8.1に戻す場合: `sudo update-alternatives --set php /usr/bin/php8.1`
- PPA登録は `add-apt-repository` ではなく sources.list.d 直書き方式で実施済み
  （Launchpad APIハング対策。Dockerfileと同方式）
