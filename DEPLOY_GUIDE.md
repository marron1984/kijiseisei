# 開運記事 展開先サイト構築ガイド

## 概要
GitHub リポジトリに保存された開運記事（txtファイル）を、Next.js サイトで表示するシステム。

## リポジトリ情報
- **リポジトリ**: `marron1984/kijiseisei`
- **ブランチ**: `claude/seo-article-good-fortune-Bb3OI`
- **記事パス**: `articles/` 配下（カテゴリ別フォルダ）

## セットアップ

### 1. 環境変数
```env
# .env.local
GITHUB_TOKEN=ghp_xxxxxxxxxxxx  # オプション（レート制限緩和用）
```

### 2. 必要ファイル
展開先の Next.js プロジェクトに以下をコピー：

- `lib/github-articles.ts` → 記事取得ユーティリティ
- `app/api/articles/route.ts` → API エンドポイント

### 3. 使い方

#### API エンドポイント
```
GET /api/articles                              → カテゴリ一覧
GET /api/articles?category=01_風水_インテリア     → 記事一覧
GET /api/articles?category=01_風水_インテリア&slug=001 → 記事全文
```

#### Server Components で直接利用
```tsx
import { getCategories, getArticlesByCategory, getArticle } from '@/lib/github-articles'

// カテゴリ一覧ページ
const categories = await getCategories()

// 記事一覧ページ
const articles = await getArticlesByCategory('01_風水_インテリア')

// 記事詳細ページ
const article = await getArticle('01_風水_インテリア', '001')
```

## 記事データ構造

### カテゴリ
| フィールド | 型 | 例 |
|-----------|------|------|
| id | string | `01_風水_インテリア` |
| name | string | `風水・インテリア` |
| number | number | `1` |

### 記事メタ
| フィールド | 型 | 例 |
|-----------|------|------|
| slug | string | `001` |
| fileName | string | `001_部屋のレイアウトで運気を上げる風水術.txt` |
| category | string | `01_風水_インテリア` |

### 記事全文
| フィールド | 型 | 説明 |
|-----------|------|------|
| title | string | 1行目のタイトル |
| content | string | 本文全体 |
| sections | string[] | ■ 区切りのセクション配列 |

## カテゴリ一覧（52カテゴリ）
01〜12: 風水、金運、仕事運、恋愛運、健康運、人間関係運、掃除、神社、季節、マインドセット、ファッション、その他
13〜25: 朝活、お金管理、子育て、旅行、食事、占い、ビジネス、自然、住まい、ペット、年代別、日常、メンタルヘルス
26〜38: 睡眠、学び、お祝い、和文化、デジタル、スポーツ、音楽、コミュニケーション、時間管理、投資、目標、哲学、季節の過ごし方
39〜52: 色彩、香り、写真、手相、数字、パワーストーン、文房具、車、言い伝え、星座、干支、夫婦、独身、総集編
