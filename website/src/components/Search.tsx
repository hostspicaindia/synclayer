'use client';

import { useState, useEffect, useRef } from 'react';
import { Search as SearchIcon, X } from 'lucide-react';
import Link from 'next/link';

interface SearchResult {
    title: string;
    description: string;
    url: string;
    category: string;
}

const searchableContent: SearchResult[] = [
    // Documentation
    { title: 'Quick Start Guide', description: 'Get started with SyncLayer in 5 minutes', url: '/docs/quick-start', category: 'Documentation' },
    { title: 'Architecture', description: 'Technical architecture and design patterns', url: '/docs/architecture', category: 'Documentation' },
    { title: 'API Reference', description: 'Complete API documentation', url: '/docs/api', category: 'Documentation' },
    { title: 'Code Examples', description: 'Real-world code examples', url: '/docs/examples', category: 'Documentation' },

    // Pages
    { title: 'Flutter SDKs', description: 'Flutter platform SDKs', url: '/flutter', category: 'Platform' },
    { title: 'SyncLayer', description: 'Local-first sync engine for Flutter', url: '/flutter/synclayer', category: 'SDK' },
    { title: 'Examples', description: 'Example projects and applications', url: '/examples', category: 'Resources' },
    { title: 'Changelog', description: 'Release history and updates', url: '/changelog', category: 'Resources' },
    { title: 'About', description: 'About HostSpica', url: '/about', category: 'Company' },
    { title: 'Contact', description: 'Get in touch', url: '/contact', category: 'Company' },
    { title: 'Community Showcase', description: 'Projects built with our SDKs', url: '/showcase', category: 'Community' },
];

export default function Search() {
    const [isOpen, setIsOpen] = useState(false);
    const [query, setQuery] = useState('');
    const [results, setResults] = useState<SearchResult[]>([]);
    const inputRef = useRef<HTMLInputElement>(null);

    // Open search with Cmd/Ctrl + K
    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
                e.preventDefault();
                setIsOpen(true);
            }
            if (e.key === 'Escape') {
                setIsOpen(false);
            }
        };

        window.addEventListener('keydown', handleKeyDown);
        return () => window.removeEventListener('keydown', handleKeyDown);
    }, []);

    // Focus input when opened
    useEffect(() => {
        if (isOpen && inputRef.current) {
            inputRef.current.focus();
        }
    }, [isOpen]);

    // Search logic
    useEffect(() => {
        if (query.trim() === '') {
            setResults([]);
            return;
        }

        const searchQuery = query.toLowerCase();
        const filtered = searchableContent.filter(
            (item) =>
                item.title.toLowerCase().includes(searchQuery) ||
                item.description.toLowerCase().includes(searchQuery) ||
                item.category.toLowerCase().includes(searchQuery)
        );

        setResults(filtered);
    }, [query]);

    if (!isOpen) {
        return (
            <button
                onClick={() => setIsOpen(true)}
                className="hidden md:flex items-center gap-2 px-3 py-2 text-sm text-gray-600 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
                aria-label="Search"
            >
                <SearchIcon className="w-4 h-4" />
                <span>Search</span>
                <kbd className="hidden lg:inline-block px-2 py-0.5 text-xs bg-white border border-gray-300 rounded">
                    ⌘K
                </kbd>
            </button>
        );
    }

    return (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-sm" onClick={() => setIsOpen(false)}>
            <div className="min-h-screen px-4 flex items-start justify-center pt-20">
                <div
                    className="w-full max-w-2xl bg-white rounded-xl shadow-2xl"
                    onClick={(e) => e.stopPropagation()}
                >
                    {/* Search Input */}
                    <div className="flex items-center gap-3 p-4 border-b border-gray-200">
                        <SearchIcon className="w-5 h-5 text-gray-400" />
                        <input
                            ref={inputRef}
                            type="text"
                            placeholder="Search documentation, pages, and more..."
                            value={query}
                            onChange={(e) => setQuery(e.target.value)}
                            className="flex-1 text-lg outline-none"
                        />
                        <button
                            onClick={() => setIsOpen(false)}
                            className="p-1 hover:bg-gray-100 rounded transition-colors"
                            aria-label="Close search"
                        >
                            <X className="w-5 h-5 text-gray-400" />
                        </button>
                    </div>

                    {/* Search Results */}
                    <div className="max-h-96 overflow-y-auto">
                        {query.trim() === '' ? (
                            <div className="p-8 text-center text-gray-500">
                                <SearchIcon className="w-12 h-12 mx-auto mb-3 text-gray-300" />
                                <p>Start typing to search...</p>
                            </div>
                        ) : results.length === 0 ? (
                            <div className="p-8 text-center text-gray-500">
                                <p>No results found for "{query}"</p>
                            </div>
                        ) : (
                            <div className="py-2">
                                {results.map((result, i) => (
                                    <Link
                                        key={i}
                                        href={result.url}
                                        onClick={() => setIsOpen(false)}
                                        className="block px-4 py-3 hover:bg-gray-50 transition-colors"
                                    >
                                        <div className="flex items-start justify-between gap-3">
                                            <div className="flex-1">
                                                <div className="font-semibold text-black mb-1">{result.title}</div>
                                                <div className="text-sm text-gray-600">{result.description}</div>
                                            </div>
                                            <span className="text-xs px-2 py-1 bg-gray-100 text-gray-600 rounded">
                                                {result.category}
                                            </span>
                                        </div>
                                    </Link>
                                ))}
                            </div>
                        )}
                    </div>

                    {/* Footer */}
                    <div className="px-4 py-3 border-t border-gray-200 flex items-center justify-between text-xs text-gray-500">
                        <div className="flex items-center gap-4">
                            <span className="flex items-center gap-1">
                                <kbd className="px-2 py-0.5 bg-gray-100 border border-gray-300 rounded">↑</kbd>
                                <kbd className="px-2 py-0.5 bg-gray-100 border border-gray-300 rounded">↓</kbd>
                                to navigate
                            </span>
                            <span className="flex items-center gap-1">
                                <kbd className="px-2 py-0.5 bg-gray-100 border border-gray-300 rounded">↵</kbd>
                                to select
                            </span>
                        </div>
                        <span className="flex items-center gap-1">
                            <kbd className="px-2 py-0.5 bg-gray-100 border border-gray-300 rounded">esc</kbd>
                            to close
                        </span>
                    </div>
                </div>
            </div>
        </div>
    );
}
