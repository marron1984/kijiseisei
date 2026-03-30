#!/bin/bash
# ============================================================
# kijiseisei → shaji 記事取り込みスクリプト
#
# GitHub の raw URL から記事を直接ダウンロードし、
# 予約投稿用のファイル名にリネームして shaji に配置する
#
# 使い方（shajiリポのルートで実行）:
#   curl -sO https://raw.githubusercontent.com/marron1984/kijiseisei/claude/seo-article-good-fortune-Bb3OI/scripts/fetch-articles.sh
#   chmod +x fetch-articles.sh
#   ./fetch-articles.sh
#
# または shaji セッションで:
#   bash <(curl -s https://raw.githubusercontent.com/marron1984/kijiseisei/claude/seo-article-good-fortune-Bb3OI/scripts/fetch-articles.sh)
# ============================================================

set -e

# === 設定 ===
REPO="marron1984/kijiseisei"
BRANCH="claude/seo-article-good-fortune-Bb3OI"
BASE_RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
BASE_API="https://api.github.com/repos/${REPO}/contents"
DEST_DIR="${1:-./public/articles}"
START_DATE="${2:-$(date -d '+1 day' +%Y-%m-%d 2>/dev/null || date -j -v+1d +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)}"

# 投稿時間（1日3回）
TIMES=("0900" "1200" "1900")

echo "============================================"
echo "  kijiseisei → shaji 記事取り込みスクリプト"
echo "============================================"
echo ""
echo "ソース: github.com/${REPO} (${BRANCH})"
echo "出力先: ${DEST_DIR}"
echo "開始日: ${START_DATE}"
echo ""

# 出力先作成
mkdir -p "$DEST_DIR"

# --- Step 1: カテゴリ一覧を取得 ---
echo "[Step 1] カテゴリ一覧を取得中..."
CATEGORIES=$(curl -s "${BASE_API}/articles?ref=${BRANCH}" | \
  python3 -c "
import json, sys
data = json.load(sys.stdin)
if isinstance(data, list):
    for item in data:
        if item.get('type') == 'dir':
            print(item['name'])
" 2>/dev/null || \
  # python3が無い場合のフォールバック
  grep -o '"name":"[^"]*"' | grep -v '\.txt' | sed 's/"name":"//;s/"//')

if [ -z "$CATEGORIES" ]; then
  echo "エラー: カテゴリを取得できませんでした。"
  echo "GitHub API のレート制限に達している可能性があります。"
  echo "GITHUB_TOKEN を設定してリトライしてください。"
  exit 1
fi

CAT_COUNT=$(echo "$CATEGORIES" | wc -l | tr -d ' ')
echo "  ${CAT_COUNT} カテゴリを検出"
echo ""

# --- Step 2: 各カテゴリの記事を取得 ---
current_date="$START_DATE"
time_index=0
total_count=0
error_count=0

while IFS= read -r category; do
  [ -z "$category" ] && continue

  echo "[Step 2] カテゴリ: ${category}"

  # カテゴリ内のファイル一覧を取得
  FILES=$(curl -s "${BASE_API}/articles/${category}?ref=${BRANCH}" | \
    python3 -c "
import json, sys
data = json.load(sys.stdin)
if isinstance(data, list):
    for item in data:
        if item.get('type') == 'file' and item['name'].endswith('.txt'):
            print(item['name'])
" 2>/dev/null || \
    grep -o '"name":"[^"]*\.txt"' | sed 's/"name":"//;s/"//')

  if [ -z "$FILES" ]; then
    echo "  → ファイルなし、スキップ"
    continue
  fi

  # カテゴリフォルダを作成
  mkdir -p "${DEST_DIR}/${category}"

  FILE_COUNT=0
  while IFS= read -r filename; do
    [ -z "$filename" ] && continue

    # 記事番号とタイトルを分離
    article_num=$(echo "$filename" | grep -oE '^[A-Z]?[0-9]+')
    title_part=$(echo "$filename" | sed "s/^[A-Z]*[0-9]*_//")

    # 予約日時を設定
    time="${TIMES[$time_index]}"
    formatted_date="${current_date}"

    # 新しいファイル名: E001_2026-04-01-0900_タイトル.txt
    new_filename="${article_num}_${formatted_date}-${time}_${title_part}"

    # ダウンロード（URLエンコード対応）
    encoded_category=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${category}'))" 2>/dev/null || echo "$category")
    encoded_filename=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${filename}'))" 2>/dev/null || echo "$filename")

    download_url="${BASE_RAW}/articles/${encoded_category}/${encoded_filename}"

    if curl -sf "$download_url" -o "${DEST_DIR}/${category}/${new_filename}" 2>/dev/null; then
      FILE_COUNT=$((FILE_COUNT + 1))
      total_count=$((total_count + 1))
    else
      echo "  ⚠ ダウンロード失敗: ${filename}"
      error_count=$((error_count + 1))
    fi

    # 時間インデックスを進める
    time_index=$(( (time_index + 1) % 3 ))

    # 3記事ごとに日付を進める
    if [ $time_index -eq 0 ]; then
      current_date=$(date -d "$current_date + 1 day" +%Y-%m-%d 2>/dev/null || \
                     date -j -v+1d -f "%Y-%m-%d" "$current_date" +%Y-%m-%d 2>/dev/null)
    fi

    # レート制限対策: 10件ごとに0.5秒待機
    if [ $((total_count % 10)) -eq 0 ]; then
      sleep 0.5
    fi

  done <<< "$FILES"

  echo "  → ${FILE_COUNT} 記事を取得"

  # カテゴリ間で1秒待機（レート制限対策）
  sleep 1

done <<< "$CATEGORIES"

echo ""
echo "============================================"
echo "  取り込み完了"
echo "============================================"
echo "取得記事数: ${total_count}"
echo "エラー数:   ${error_count}"
echo "最終投稿日: ${current_date}"
echo "出力先:     ${DEST_DIR}"
echo ""
echo "次のステップ:"
echo "  git add ${DEST_DIR}"
echo "  git commit -m 'feat: 開運記事${total_count}本を予約投稿設定'"
echo "  git push"
