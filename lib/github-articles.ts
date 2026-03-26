/**
 * GitHub API経由で開運記事を取得するユーティリティ
 *
 * 使い方:
 *   import { getCategories, getArticlesByCategory, getArticle } from '@/lib/github-articles'
 */

const REPO_OWNER = 'marron1984'
const REPO_NAME = 'kijiseisei'
const BRANCH = 'claude/seo-article-good-fortune-Bb3OI'
const ARTICLES_PATH = 'articles'

const GITHUB_TOKEN = process.env.GITHUB_TOKEN // オプション（レート制限緩和用）

interface GitHubContent {
  name: string
  path: string
  type: 'file' | 'dir'
  download_url: string | null
}

export interface Category {
  id: string       // "01_風水_インテリア"
  name: string     // "風水・インテリア"
  number: number   // 1
  path: string
}

export interface ArticleMeta {
  id: string       // "001_部屋のレイアウトで運気を上げる風水術"
  number: number   // 1
  slug: string     // "001"
  fileName: string
  category: string
  path: string
}

export interface Article extends ArticleMeta {
  title: string
  content: string
  sections: string[]
}

function headers(): HeadersInit {
  const h: HeadersInit = {
    Accept: 'application/vnd.github.v3+json',
  }
  if (GITHUB_TOKEN) {
    h.Authorization = `Bearer ${GITHUB_TOKEN}`
  }
  return h
}

function apiUrl(path: string): string {
  return `https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/contents/${path}?ref=${BRANCH}`
}

/**
 * カテゴリ名を整形する
 * "01_風水_インテリア" → "風水・インテリア"
 */
function formatCategoryName(dirName: string): string {
  const parts = dirName.split('_')
  // 先頭の数字部分を除去
  const nameParts = parts.slice(1)
  return nameParts.join('・')
}

/**
 * 全カテゴリ一覧を取得
 */
export async function getCategories(): Promise<Category[]> {
  const res = await fetch(apiUrl(ARTICLES_PATH), {
    headers: headers(),
    next: { revalidate: 3600 }, // 1時間キャッシュ
  })

  if (!res.ok) {
    throw new Error(`Failed to fetch categories: ${res.status}`)
  }

  const items: GitHubContent[] = await res.json()

  return items
    .filter((item) => item.type === 'dir')
    .map((item) => {
      const num = parseInt(item.name.split('_')[0], 10)
      return {
        id: item.name,
        name: formatCategoryName(item.name),
        number: num,
        path: item.path,
      }
    })
    .sort((a, b) => a.number - b.number)
}

/**
 * カテゴリ内の記事一覧を取得（メタ情報のみ）
 */
export async function getArticlesByCategory(
  categoryId: string
): Promise<ArticleMeta[]> {
  const res = await fetch(apiUrl(`${ARTICLES_PATH}/${categoryId}`), {
    headers: headers(),
    next: { revalidate: 3600 },
  })

  if (!res.ok) {
    throw new Error(`Failed to fetch articles: ${res.status}`)
  }

  const items: GitHubContent[] = await res.json()

  return items
    .filter((item) => item.type === 'file' && item.name.endsWith('.txt'))
    .map((item) => {
      const baseName = item.name.replace('.txt', '')
      const num = parseInt(baseName.split('_')[0], 10)
      return {
        id: baseName,
        number: num,
        slug: baseName.split('_')[0], // "001"
        fileName: item.name,
        category: categoryId,
        path: item.path,
      }
    })
    .sort((a, b) => a.number - b.number)
}

/**
 * txtファイルからタイトルと本文を抽出
 */
function parseTxtContent(raw: string): { title: string; content: string } {
  const lines = raw.split('\n')
  const title = lines[0]?.trim() || ''
  // タイトル行と区切り線を除いた本文
  const contentStart = lines.findIndex(
    (line, i) => i > 0 && line.includes('===')
  )
  const content =
    contentStart >= 0
      ? lines
          .slice(contentStart + 1)
          .join('\n')
          .trim()
      : lines.slice(1).join('\n').trim()

  return { title, content }
}

/**
 * 記事の全文を取得
 */
export async function getArticle(
  categoryId: string,
  slug: string
): Promise<Article | null> {
  // まずカテゴリ内のファイル一覧を取得してslugに一致するファイルを探す
  const articles = await getArticlesByCategory(categoryId)
  const meta = articles.find((a) => a.slug === slug)
  if (!meta) return null

  const rawUrl = `https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}/${meta.path}`
  const res = await fetch(rawUrl, {
    next: { revalidate: 3600 },
  })

  if (!res.ok) return null

  const raw = await res.text()
  const { title, content } = parseTxtContent(raw)

  // セクション分割（■ で始まる行をセクション区切りとする）
  const sections = content
    .split(/(?=^■)/m)
    .map((s) => s.trim())
    .filter(Boolean)

  return {
    ...meta,
    title,
    content,
    sections,
  }
}

/**
 * 全記事一覧を取得（サイトマップ生成用など）
 */
export async function getAllArticles(): Promise<ArticleMeta[]> {
  const categories = await getCategories()
  const allArticles: ArticleMeta[] = []

  for (const cat of categories) {
    const articles = await getArticlesByCategory(cat.id)
    allArticles.push(...articles)
  }

  return allArticles.sort((a, b) => a.number - b.number)
}
