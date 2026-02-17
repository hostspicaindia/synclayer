import type { Metadata } from 'next';
import Link from 'next/link';
import { ArrowLeft, Calendar, Clock, Share2 } from 'lucide-react';
import { notFound } from 'next/navigation';

interface BlogPost {
    slug: string;
    title: string;
    excerpt: string;
    content: string;
    date: string;
    readTime: string;
    category: string;
    author: string;
}

const blogPosts: Record<string, BlogPost> = {
    'introducing-synclayer': {
        slug: 'introducing-synclayer',
        title: 'Introducing SyncLayer: The Future of Offline-First Flutter Apps',
        excerpt: 'Learn how SyncLayer simplifies building offline-first applications with automatic synchronization and conflict resolution.',
        content: `
# Introducing SyncLayer

We're excited to announce SyncLayer, a production-ready local-first sync engine for Flutter applications.

## Why SyncLayer?

Building offline-first applications is challenging. Developers need to handle:
- Local data storage
- Network synchronization
- Conflict resolution
- Queue management
- Error handling

SyncLayer solves all of these problems with a clean, type-safe API.

## Key Features

### 1. Offline-First Architecture
Your app works perfectly without an internet connection. All data is stored locally using Isar database.

### 2. Automatic Synchronization
SyncLayer automatically syncs your data when the device comes online. No manual intervention required.

### 3. Conflict Resolution
Built-in conflict resolution strategies handle data conflicts intelligently.

### 4. Backend Agnostic
Works with any backend: REST APIs, Firebase, Supabase, or custom solutions.

## Getting Started

\`\`\`dart
await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos'],
    conflictStrategy: ConflictStrategy.lastWriteWins,
  ),
);
\`\`\`

## What's Next?

We're continuously improving SyncLayer based on community feedback. Check out our [documentation](/docs) to learn more.
    `,
        date: 'February 15, 2026',
        readTime: '5 min read',
        category: 'Product',
        author: 'HostSpica Team',
    },
    'building-offline-first-apps': {
        slug: 'building-offline-first-apps',
        title: 'Building Offline-First Apps: Best Practices and Patterns',
        excerpt: 'Explore the best practices for building robust offline-first applications.',
        content: `
# Building Offline-First Apps

Offline-first architecture is becoming essential for modern mobile applications. Here's what you need to know.

## Best Practices

1. **Always store data locally first**
2. **Sync in the background**
3. **Handle conflicts gracefully**
4. **Provide clear sync status**
5. **Test offline scenarios**

## Common Patterns

### Queue-Based Sync
Queue all operations and process them when online.

### Event-Driven Updates
Listen to data changes and update UI reactively.

### Optimistic Updates
Update UI immediately, sync in background.

## Conclusion

Building offline-first apps requires careful planning, but the user experience benefits are worth it.
    `,
        date: 'February 10, 2026',
        readTime: '8 min read',
        category: 'Tutorial',
        author: 'HostSpica Team',
    },
    'conflict-resolution-strategies': {
        slug: 'conflict-resolution-strategies',
        title: 'Understanding Conflict Resolution Strategies',
        excerpt: 'A deep dive into conflict resolution strategies in distributed systems.',
        content: `
# Conflict Resolution Strategies

When building distributed systems, conflicts are inevitable. Here's how to handle them.

## Strategy 1: Last Write Wins
The most recent modification takes precedence.

**Pros:** Simple, predictable
**Cons:** May lose data

## Strategy 2: Server Wins
Server data always overrides local changes.

**Pros:** Authoritative source
**Cons:** Local changes may be lost

## Strategy 3: Client Wins
Local changes always take precedence.

**Pros:** User autonomy
**Cons:** May conflict with server state

## Choosing the Right Strategy

Consider your use case:
- Single user? Last Write Wins
- Authoritative server? Server Wins
- User autonomy? Client Wins

## Conclusion

Choose the strategy that best fits your application's needs.
    `,
        date: 'February 5, 2026',
        readTime: '10 min read',
        category: 'Technical',
        author: 'HostSpica Team',
    },
};

export async function generateMetadata({ params }: { params: { slug: string } }): Promise<Metadata> {
    const post = blogPosts[params.slug];

    if (!post) {
        return {
            title: 'Post Not Found',
        };
    }

    return {
        title: post.title,
        description: post.excerpt,
    };
}

export default function BlogPostPage({ params }: { params: { slug: string } }) {
    const post = blogPosts[params.slug];

    if (!post) {
        notFound();
    }

    return (
        <div className="min-h-screen bg-white">
            <article className="px-6 py-12">
                <div className="max-w-4xl mx-auto">
                    <Link
                        href="/blog"
                        className="inline-flex items-center text-gray-700 hover:text-black mb-8 transition-colors"
                    >
                        <ArrowLeft className="w-4 h-4 mr-2" />
                        Back to Blog
                    </Link>

                    <div className="mb-8">
                        <div className="flex items-center gap-2 mb-4">
                            <span className="px-3 py-1 bg-gray-100 text-gray-700 text-sm font-medium rounded-full">
                                {post.category}
                            </span>
                        </div>
                        <h1 className="text-5xl font-bold text-black mb-4">{post.title}</h1>
                        <div className="flex items-center gap-4 text-gray-600">
                            <div className="flex items-center gap-1">
                                <Calendar className="w-4 h-4" />
                                <span>{post.date}</span>
                            </div>
                            <div className="flex items-center gap-1">
                                <Clock className="w-4 h-4" />
                                <span>{post.readTime}</span>
                            </div>
                            <span>By {post.author}</span>
                        </div>
                    </div>

                    <div className="prose prose-lg max-w-none">
                        <div className="whitespace-pre-wrap text-gray-700 leading-relaxed">
                            {post.content}
                        </div>
                    </div>

                    <div className="mt-12 pt-8 border-t border-gray-200">
                        <div className="flex items-center justify-between">
                            <div>
                                <h3 className="text-lg font-bold text-black mb-2">Share this post</h3>
                                <div className="flex gap-3">
                                    <button className="p-2 hover:bg-gray-100 rounded transition-colors">
                                        <Share2 className="w-5 h-5 text-gray-600" />
                                    </button>
                                </div>
                            </div>
                            <Link
                                href="/blog"
                                className="inline-flex items-center px-6 py-3 bg-black text-white rounded-lg hover:bg-gray-800 transition-colors font-semibold"
                            >
                                Read More Posts
                            </Link>
                        </div>
                    </div>
                </div>
            </article>
        </div>
    );
}

export async function generateStaticParams() {
    return Object.keys(blogPosts).map((slug) => ({
        slug,
    }));
}
