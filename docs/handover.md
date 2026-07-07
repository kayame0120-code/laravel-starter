# laravel-starter 引き継ぎ書

- version: v1.1
- updated: 2026-07-07
- sources: laravel-starterテンプレ構築セッション（2026-07-07・Fable5）/ live-souls初回デプロイセッション（2026-07-07・Fable5。⑤〜⑨実走・v1.1格上げ根拠）

## 確定事項（再調査・再議論禁止。変更するなら人間に確認）
- テンプレ: github.com/kayame0120-code/laravel-starter（Template repository化済み）
- Laravel 12 / PHP 8.2。**11以下はEOL + composer security advisoryブロックで選択不可**
- 構成: ローカルSQLite / 本番Fly Postgres（`DATABASE_URL`一本。.envにpgsql設定は書かない）
- fly.tomlは `/up` ヘルスチェック付き（コールドスタート502防止・ASYLUM実証済み）
- CLAUDE.md（恒久ルール）+ .claude/settings.json（deny付き）同梱。
  **アプリ固有は docs/spec.md へ。CLAUDE.md は編集しない**
- 新アプリ立ち上げはスニペット①〜⑨（v1.1格上げ版）が正。
  `fly launch` は使わない（`fly apps create`）

## 検証済みの範囲
- Use this template → clone → ローカル起動（煙テスト合格 2026-07-07）
- Fly実デプロイ⑤〜⑨: **実証済み（2026-07-07・live-souls）**。
  apps create → postgres create/attach → secrets set → deploy → ssh migrate まで完走。
  本番URLの `/up` が200、`migrate:status` 全Ranを確認
- 途中で発生した事故2件はスニペットv1.1に対策として反映済み:
  1. postgres createの対話でProduction(3ノード)を誤選択 → フラグ指定で対話を回避
  2. APP_KEYに `$` 付きで貼りシェル変数展開で鍵が破損（Encrypter 500） → 2段階手動 + シングルクォート方式に変更

## 環境メモ（片倉のローカル固有）
- ローカルのデフォルトPHPは 8.2 に変更済み（Ondrej PPA・8.1と共存）
- 学校課題等で8.1に戻す場合: `sudo update-alternatives --set php /usr/bin/php8.1`
- PPA登録は `add-apt-repository` ではなく sources.list.d 直書き方式で実施済み
  （Launchpad APIハング対策。Dockerfileと同方式）
