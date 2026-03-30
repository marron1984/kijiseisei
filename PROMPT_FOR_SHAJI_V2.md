# shajiセッションに貼り付けるプロンプト（V2）

以下をそのまま shaji リポの Claude Code セッションに貼り付けてください。

---

```
kijiseisei リポから開運記事（約1200本）を取り込んで予約投稿設定してください。

## 手順

### 1. 取り込みスクリプトをダウンロードして実行

以下のコマンドでスクリプトをダウンロードし、実行してください:

```bash
curl -sO "https://raw.githubusercontent.com/marron1984/kijiseisei/claude/seo-article-good-fortune-Bb3OI/scripts/fetch-articles.sh"
chmod +x fetch-articles.sh
./fetch-articles.sh ./public/articles
```

このスクリプトは:
- GitHub API で kijiseisei リポの全カテゴリ・全記事を自動取得
- 1日3記事ペース（9時/12時/19時）で予約日時を自動設定
- ファイル名を `E001_2026-04-01-0900_タイトル.txt` 形式にリネーム
- public/articles/ にカテゴリ別フォルダで配置

### 2. もしスクリプトが動かない場合

python3 が必要です。なければ以下で代替:

```bash
# 直接 git clone して手動コピー
git clone -b claude/seo-article-good-fortune-Bb3OI --depth 1 https://github.com/marron1984/kijiseisei.git /tmp/kijiseisei
cp -r /tmp/kijiseisei/articles/* ./public/articles/
rm -rf /tmp/kijiseisei
```

クローンした場合はファイル名に予約日時がないので、
以下のようなリネームスクリプトを作って予約設定してください:

```bash
# 予約日時リネームスクリプト（shaji側で実行）
START_DATE=$(date -d '+1 day' +%Y-%m-%d)
TIMES=("0900" "1200" "1900")
current_date="$START_DATE"
time_index=0

find ./public/articles -name "*.txt" | sort | while read filepath; do
  dir=$(dirname "$filepath")
  filename=$(basename "$filepath")
  num=$(echo "$filename" | grep -oE '^[A-Z]?[0-9]+')
  title=$(echo "$filename" | sed "s/^[A-Z]*[0-9]*_//")
  time="${TIMES[$time_index]}"
  new_name="${num}_${current_date}-${time}_${title}"
  mv "$filepath" "${dir}/${new_name}"
  time_index=$(( (time_index + 1) % 3 ))
  if [ $time_index -eq 0 ]; then
    current_date=$(date -d "$current_date + 1 day" +%Y-%m-%d)
  fi
done
```

### 3. コミット・プッシュ

```bash
git add public/articles/
git commit -m "feat: 開運記事を予約投稿設定で取り込み"
git push
```

## リポジトリ情報
- Owner: marron1984
- Repo: kijiseisei
- Branch: claude/seo-article-good-fortune-Bb3OI
- 記事パス: articles/ 配下（100+カテゴリ、1200+記事）

## 記事テキストのフォーマット
- 1行目: タイトル
- 3行目: ====（区切り線）
- 以降: 本文（■ でセクション区切り）

## 予約投稿ルール
- 1日3記事（朝9時/昼12時/夜19時）
- 開始日: 明日から
- ファイル名: `001_2026-04-01-0900_タイトル.txt`
- 1200記事 ÷ 3 = 約400日分（約13ヶ月）
```
