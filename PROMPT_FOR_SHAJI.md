# shajiセッションに渡すプロンプト

以下をそのままshajiリポのClaude Codeセッションに貼り付けてください。

---

## プロンプト

```
開運記事（約785本）を kijiseisei リポから取り込んで予約投稿設定してください。

## 記事の取得方法

記事は GitHub API 経由で取得します。以下のエンドポイントを使ってください。

### 1. カテゴリ一覧を取得
```bash
curl -s "https://api.github.com/repos/marron1984/kijiseisei/contents/articles?ref=claude/seo-article-good-fortune-Bb3OI" | jq '.[].name'
```

### 2. カテゴリ内の記事一覧を取得
```bash
curl -s "https://api.github.com/repos/marron1984/kijiseisei/contents/articles/01_風水_インテリア?ref=claude/seo-article-good-fortune-Bb3OI" | jq '.[].name'
```

### 3. 記事本文を取得
```bash
curl -s "https://raw.githubusercontent.com/marron1984/kijiseisei/claude/seo-article-good-fortune-Bb3OI/articles/01_風水_インテリア/001_部屋のレイアウトで運気を上げる風水術.txt"
```

## リポジトリ情報
- Owner: marron1984
- Repo: kijiseisei
- Branch: claude/seo-article-good-fortune-Bb3OI
- 記事パス: articles/ 配下（52カテゴリ、約785記事）

## フォルダ構造
```
articles/
├── 01_風水_インテリア/
│   ├── 001_部屋のレイアウトで運気を上げる風水術.txt
│   ├── 002_運気を呼び込む玄関づくり.txt
│   └── ...（20記事）
├── 02_金運/
│   ├── 021_金運を上げる方法15選.txt
│   └── ...（20記事）
├── ...（全52カテゴリ）
└── 52_開運_総集編_まとめ/
    └── ...
```

## 記事テキストのフォーマット
- 1行目: タイトル
- 3行目: ====（区切り線）
- 以降: 本文（■ でセクション区切り）

## やってほしいこと

### Step 1: 記事取り込みスクリプトを作成
GitHub API で kijiseisei リポから全記事を取得し、shaji の public/articles/ にコピーするスクリプトを作成してください。

### Step 2: 予約日時を自動振り分け
- 1日3記事ペース（朝9時/昼12時/夜19時）
- 開始日: 明日から
- ファイル名ルール: `001_2026-03-27-0900_タイトル.txt`
- カテゴリフォルダはそのまま維持

### Step 3: 実行してコミット・プッシュ
スクリプトを実行し、全記事を予約投稿設定してコミット・プッシュしてください。

### 補足
- 記事は即時公開ではなく、すべて予約投稿にする
- カテゴリの順番通りに投稿（01→02→03...→52）
- 785記事 ÷ 3記事/日 = 約262日分（約8.7ヶ月）
- GitHub API のレート制限に注意（認証なしは60回/時、GITHUB_TOKEN設定で5000回/時）
- レート制限を避けるため、取得は raw.githubusercontent.com 経由がおすすめ（レート制限なし）
```

---

## 補足説明

### なぜこの方法？
- kijiseisei と shaji は別リポジトリ
- shaji セッションから kijiseisei に直接アクセスできない場合がある
- GitHub の公開 API / raw URL なら外部からでもアクセス可能
- raw.githubusercontent.com はレート制限がないため大量取得に最適

### もし API アクセスもできない場合
ローカルで以下を実行してください：

```bash
# kijiseisei リポをクローン
git clone -b claude/seo-article-good-fortune-Bb3OI https://github.com/marron1984/kijiseisei.git /tmp/kijiseisei

# shaji リポに記事をコピー
cp -r /tmp/kijiseisei/articles/* /path/to/shaji/public/articles/

# shaji セッションで予約日時の振り分けを依頼
```
