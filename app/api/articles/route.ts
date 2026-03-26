import { NextResponse } from 'next/server'
import { getCategories, getArticlesByCategory, getArticle } from '@/lib/github-articles'

/**
 * GET /api/articles
 *   → 全カテゴリ一覧を返す
 *
 * GET /api/articles?category=01_風水_インテリア
 *   → カテゴリ内の記事一覧を返す
 *
 * GET /api/articles?category=01_風水_インテリア&slug=001
 *   → 記事の全文を返す
 */
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const category = searchParams.get('category')
  const slug = searchParams.get('slug')

  try {
    if (!category) {
      const categories = await getCategories()
      return NextResponse.json({ categories })
    }

    if (!slug) {
      const articles = await getArticlesByCategory(category)
      return NextResponse.json({ category, articles })
    }

    const article = await getArticle(category, slug)
    if (!article) {
      return NextResponse.json({ error: 'Article not found' }, { status: 404 })
    }

    return NextResponse.json({ article })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error'
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
