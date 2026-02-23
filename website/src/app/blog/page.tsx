import type { Metadata } from 'next';
import Link from 'next/link';
import { Calendar, Clock, ArrowRight } from 'lucide-react';

export const metadata: Metadata = {
    title: 'Blog',
    description: 'Latest updates, tutorials, and insights from HostSpica',
};

interface BlogPost {
    slug: string;
    title: string;
    excerpt: string;
    date: string;
    readTime: string;
    category: string;
    author: string;
}

const blogPosts: BlogPost[] = [
    {
        slug: 'introducing-synclayer',
        title: 'Introducing SyncLayer: The Future of Offline-First Flutter Apps',
        excerpt: 'Learn how SyncLayer simplifies building offline-first applications with automatic synchronization and conflict resolution.',
        date: 'February 15, 2026',
        readTime: '5 min read',
        category: 'Product',
        author: 'HostSpica Team',
    },
    {
        slug: 'building-offline-first-apps',
        title: 'Building Offline-First Apps: Best Practices and Patterns',
        excerpt: 'Explore the best practices for building robust offline-first applications that provide seamless user experiences.',
        date: 'February 10, 2026',
        readTime: '8 min read',
        category: 'Tutorial',
        author: 'HostSpica Team',
    },
    {
        slug: 'conflict-resolution-strategies',
        title: 'Understanding Conflict Resolution Strategies in Distributed Systems',
        excerpt: 'A deep dive into different conflict resolution strategies and when to use each one in your applications.',
        date: 'February 5, 2026',
        readTime: '10 min read',
        category: 'Technical',
        author: 'HostSpica Team',
    },
];

export default function BlogPage() {
    return (
        <div className="min-h-screen bg-white">
            <section className="px-6 pt-20 pb-24">
                <div className="max-w-6xl mx-auto">
                    <div className="text-center mb-16">
                        <h1 className="text-5xl font-bold text-black mb-4">Blog</h1>
                        <p className="text-xl text-gray-700 max-w-2xl mx-auto">
                            Latest updates, tutorials, and insights from the HostSpica team
                        </p>
                    </div>

                    {/* Featured Post */}
                    {blogPosts.length > 0 && (
                        <div className="mb-12">
                            <FeaturedPost post={blogPosts[0]} />
                        </div>
                    )}

                    {/* All Posts */}
                    <div className="grid md:grid-cols-2 gap-6">
                        {blogPosts.slice(1).map((post, i) => (
                            <BlogCard key={i} post={post} />
                        ))}
                    </div>

                    {/* Coming Soon Message */}
                    <div className="mt-12 bg-blue-50 border border-blue-200 rounded-xl p-8 text-center">
                        <h2 className="text-2xl font-bold text-black mb-2">More Content Coming Soon</h2>
                        <p className="text-gray-700 mb-4">
                            We're working on more tutorials, guides, and technical deep dives. Stay tuned!
                        </p>
                        <div className="flex flex-col sm:flex-row gap-4 justify-center">
                            <a
                                href="https://github.com/hostspicaindia"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="inline-flex items-center justify-center px-6 py-3 bg-black text-white rounded-lg hover:bg-gray-800 transition-colors font-semibold"
                            >
                                Follow on GitHub
                            </a>
                            <a
                                href="https://twitter.com/hostspicaindia"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="inline-flex items-center justify-center px-6 py-3 border-2 border-gray-300 text-black rounded-lg hover:border-black transition-colors font-semibold"
                            >
                                Follow on Twitter
                            </a>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    );
}

function FeaturedPost({ post }: { post: BlogPost }) {
    return (
        <Link
            href={`/blog/${post.slug}`}
            className="block bg-gradient-to-r from-blue-50 to-purple-50 border border-blue-200 rounded-2xl p-8 hover:border-black transition-colors"
        >
            <div className="flex items-center gap-2 mb-4">
                <span className="px-3 py-1 bg-blue-600 text-white text-xs font-semibold rounded-full">
                    Featured
                </span>
                <span className="px-3 py-1 bg-white text-gray-700 text-xs font-medium rounded-full border border-gray-200">
                    {post.category}
                </span>
            </div>
            <h2 className="text-3xl font-bold text-black mb-3">{post.title}</h2>
            <p className="text-lg text-gray-700 mb-4">{post.excerpt}</p>
            <div className="flex items-center gap-4 text-sm text-gray-600">
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
        </Link>
    );
}

function BlogCard({ post }: { post: BlogPost }) {
    return (
        <Link
            href={`/blog/${post.slug}`}
            className="block bg-white border border-gray-200 rounded-xl p-6 hover:border-black transition-colors"
        >
            <div className="flex items-center gap-2 mb-3">
                <span className="px-3 py-1 bg-gray-100 text-gray-700 text-xs font-medium rounded-full">
                    {post.category}
                </span>
            </div>
            <h3 className="text-xl font-bold text-black mb-2">{post.title}</h3>
            <p className="text-gray-700 mb-4">{post.excerpt}</p>
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-3 text-sm text-gray-600">
                    <div className="flex items-center gap-1">
                        <Calendar className="w-4 h-4" />
                        <span>{post.date}</span>
                    </div>
                    <div className="flex items-center gap-1">
                        <Clock className="w-4 h-4" />
                        <span>{post.readTime}</span>
                    </div>
                </div>
                <ArrowRight className="w-5 h-5 text-gray-400" />
            </div>
        </Link>
    );
}
