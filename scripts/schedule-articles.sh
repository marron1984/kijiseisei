#!/bin/bash
# ============================================================
# 記事スケジュール振り分けスクリプト
#
# kijiseisei の記事を予約投稿用にリネームし、
# shaji リポの public/articles/ にコピーする
#
# 使い方:
#   ./scripts/schedule-articles.sh /path/to/shaji/public/articles
#
# 投稿スケジュール:
#   1日3記事（朝9時/昼12時/夜19時）
#   785記事 ÷ 3 = 約262日分（約8.7ヶ月）
# ============================================================

set -e

DEST_DIR="${1:-./output}"
SOURCE_DIR="$(dirname "$0")/../articles"
START_DATE="${2:-$(date +%Y-%m-%d)}"  # デフォルトは今日

# 投稿時間（1日3回）
TIMES=("0900" "1200" "1900")

echo "=== 記事スケジュール振り分けスクリプト ==="
echo "ソース: $SOURCE_DIR"
echo "出力先: $DEST_DIR"
echo "開始日: $START_DATE"
echo ""

# 出力ディレクトリ作成
mkdir -p "$DEST_DIR"

# 全記事をリストアップ（番号順にソート）
ARTICLE_LIST=$(find "$SOURCE_DIR" -name "*.txt" -type f | sort)
TOTAL=$(echo "$ARTICLE_LIST" | wc -l)
echo "総記事数: $TOTAL"
echo "予定期間: $(( (TOTAL + 2) / 3 )) 日間"
echo ""

# 日付計算用
current_date="$START_DATE"
time_index=0
count=0

while IFS= read -r filepath; do
    # カテゴリフォルダ名を取得
    category=$(basename "$(dirname "$filepath")")
    filename=$(basename "$filepath")

    # 番号とタイトルを分離
    article_num=$(echo "$filename" | grep -oP '^\d+')
    title_part=$(echo "$filename" | sed 's/^[0-9]*_//')

    # 予約日時を設定
    time="${TIMES[$time_index]}"
    scheduled_date=$(echo "$current_date" | tr -d '-')

    # 新しいファイル名: 001_2026-03-27-0900_タイトル.txt
    formatted_date=$(echo "$current_date" | tr -d ' ')
    new_filename="${article_num}_${formatted_date}-${time}_${title_part}"

    # カテゴリフォルダを出力先に作成してコピー
    mkdir -p "$DEST_DIR/$category"
    cp "$filepath" "$DEST_DIR/$category/$new_filename"

    count=$((count + 1))

    # 時間インデックスを進める
    time_index=$(( (time_index + 1) % 3 ))

    # 3記事ごとに日付を進める
    if [ $time_index -eq 0 ]; then
        current_date=$(date -d "$current_date + 1 day" +%Y-%m-%d 2>/dev/null || \
                       date -j -v+1d -f "%Y-%m-%d" "$current_date" +%Y-%m-%d 2>/dev/null)
    fi

    # 進捗表示（50件ごと）
    if [ $((count % 50)) -eq 0 ]; then
        echo "  $count / $TOTAL 完了..."
    fi

done <<< "$ARTICLE_LIST"

echo ""
echo "=== 完了 ==="
echo "処理記事数: $count"
echo "最終投稿日: $current_date"
echo "出力先: $DEST_DIR"
echo ""
echo "次のステップ:"
echo "  cd /path/to/shaji"
echo "  git add public/articles/"
echo "  git commit -m 'feat: 開運記事${count}本を予約投稿設定'"
echo "  git push"
