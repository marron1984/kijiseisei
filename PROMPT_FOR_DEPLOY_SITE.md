# 展開先サイト開発プロンプト

以下のプロンプトを展開先の Next.js プロジェクトで Claude Code に渡してください。

---

## プロンプト

```
GitHub リポジトリ `marron1984/kijiseisei` の `claude/seo-article-good-fortune-Bb3OI` ブランチに、
「開運」をテーマにした SEO 記事が約800本、txt ファイルとして保存されています。

以下の構成で記事表示サイトを構築してください。

## リポジトリ構造
articles/
├── 01_風水_インテリア/
│   ├── 001_部屋のレイアウトで運気を上げる風水術.txt
│   ├── 002_運気を呼び込む玄関づくり.txt
│   └── ...
├── 02_金運/
│   └── ...
└── （計52カテゴリ、約800記事）

## txt ファイルのフォーマット
- 1行目: タイトル
- 3行目: ====（区切り線）
- 以降: 本文（■ でセクション区切り）

## 実装要件

### 1. 記事取得ユーティリティ (`lib/github-articles.ts`)
- GitHub API (raw.githubusercontent.com) 経由で記事を取得
- リポジトリ情報:
  - Owner: marron1984
  - Repo: kijiseisei
  - Branch: claude/seo-article-good-fortune-Bb3OI
  - Path: articles/
- ISR (Incremental Static Regeneration) で1時間キャッシュ
- 環境変数 `GITHUB_TOKEN`（オプション、レート制限緩和用）

### 2. ページ構成
- `/articles` → カテゴリ一覧ページ（52カテゴリをカード形式で表示）
- `/articles/[category]` → カテゴリ内の記事一覧ページ
- `/articles/[category]/[slug]` → 記事詳細ページ

### 3. 記事詳細ページの要件
- タイトルを h1 で表示
- 本文の ■ セクションを見出し（h2）として整形
- パンくずリスト（トップ > カテゴリ > 記事タイトル）
- 関連記事（同カテゴリの他の記事）をサイドバーまたは記事下に表示
- SEO メタタグ（title, description）を記事内容から自動生成

### 4. カテゴリ一覧ページの要件
- カテゴリ名と記事数を表示
- カテゴリ番号で並び替え
- カテゴリ名のフォーマット: "01_風水_インテリア" → "風水・インテリア"

### 5. デザイン
- Tailwind CSS 使用
- 信頼感があり、やや高級感のあるデザイン
- モバイルレスポンシブ
- カラースキーム: 落ち着いたゴールド系（#B8860B）と白ベース
- フォント: 游明朝 or Noto Serif JP（本文）、Noto Sans JP（見出し）

### 6. SEO 対策
- generateMetadata で各ページのメタデータを動的生成
- sitemap.xml を自動生成（全記事のURL）
- robots.txt
- 構造化データ（JSON-LD）で Article マークアップ
- パンくずリストの構造化データ

### 7. API ルート
- `GET /api/articles` → カテゴリ一覧 JSON
- `GET /api/articles?category=xxx` → 記事一覧 JSON
- `GET /api/articles?category=xxx&slug=001` → 記事全文 JSON

### 8. パフォーマンス
- ISR で静的生成 + 1時間ごとに再検証
- generateStaticParams で主要ページを事前ビルド
- 画像は不要（テキストコンテンツのみ）

## 技術スタック
- Next.js 14+ (App Router)
- TypeScript
- Tailwind CSS
- GitHub API (fetch)
```

---

## 補足
- `GITHUB_TOKEN` は GitHub の Personal Access Token（read権限のみで可）
- トークンなしでも動作するが、API レート制限（60回/時）に注意
- トークンありの場合は 5,000回/時
