import type { Metadata } from 'next';
import Link from 'next/link';
import { Calendar, Tag, Github as GithubIcon } from 'lucide-react';

export const metadata: Metadata = {
    title: 'Changelog',
    description: 'SyncLayer release history and updates',
};

export default function ChangelogPage() {
    return (
        <div className="min-h-screen bg-white">
            <section className="px-6 py-12">
                <div className="max-w-4xl mx-auto">
                    <h1 className="text-5xl font-bold text-black mb-4">Changelog</h1>
                    <p className="text-xl text-gray-700 mb-12">
                        Track the evolution of SyncLayer with detailed release notes
                    </p>

                    <div className="space-y-8">
                        <Release
                            version="0.2.0-beta.7"
                            date="February 17, 2026"
                            type="beta"
                            changes={[
                                {
                                    type: 'added',
                                    items: [
                                        'Added structured logging framework with configurable levels',
                                        'Added comprehensive metrics and telemetry system',
                                        'Added pagination for pull sync (90% less memory)',
                                        'Added composite database indexes (50-80% faster queries)',
                                        'Added batch queue operations (70% faster bulk inserts)',
                                        'Added 30-second timeout for sync operations',
                                        'Added data validation for JSON-serializability',
                                    ]
                                },
                                {
                                    type: 'changed',
                                    items: [
                                        'Replaced weak hash function with SHA-256',
                                        'Improved conflict detection with 5-second grace period',
                                        'Enhanced null safety throughout codebase',
                                        'Improved concurrent sync prevention',
                                    ]
                                },
                                {
                                    type: 'fixed',
                                    items: [
                                        'Fixed race condition in save() method',
                                        'Fixed missing error handling in watch() streams',
                                        'Fixed transaction rollback for batch operations',
                                        'Fixed event stream disposal issues',
                                    ]
                                },
                                {
                                    type: 'security',
                                    items: [
                                        'Upgraded to cryptographic SHA-256 hashing',
                                        'Added proper data integrity checks',
                                    ]
                                }
                            ]}
                            githubUrl="https://github.com/hostspicaindia/synclayer/releases/tag/v0.2.0-beta.7"
                        />

                        <Release
                            version="0.2.0-beta.5"
                            date="February 15, 2026"
                            type="beta"
                            changes={[
                                {
                                    type: 'added',
                                    items: [
                                        'Added comprehensive test suite with 48 tests',
                                        'Added performance benchmarks',
                                        'Added integration tests for sync flow',
                                    ]
                                },
                                {
                                    type: 'changed',
                                    items: [
                                        'Made baseUrl optional when using custom adapters',
                                        'Improved error handling in sync engine',
                                        'Updated documentation with examples',
                                    ]
                                },
                                {
                                    type: 'fixed',
                                    items: [
                                        'Fixed conflict resolution edge cases',
                                        'Fixed memory leaks in event listeners',
                                        'Fixed retry logic timing issues',
                                    ]
                                }
                            ]}
                            githubUrl="https://github.com/hostspicaindia/synclayer/releases/tag/v0.2.0-beta.5"
                        />

                        <Release
                            version="0.2.0-beta.4"
                            date="February 10, 2026"
                            type="beta"
                            changes={[
                                {
                                    type: 'added',
                                    items: [
                                        'Added Appwrite adapter',
                                        'Added event system for monitoring',
                                        'Added connectivity detection',
                                    ]
                                },
                                {
                                    type: 'changed',
                                    items: [
                                        'Improved sync performance',
                                        'Updated dependencies',
                                    ]
                                }
                            ]}
                            githubUrl="https://github.com/hostspicaindia/synclayer/releases/tag/v0.2.0-beta.4"
                        />

                        <Release
                            version="0.2.0-beta.3"
                            date="February 5, 2026"
                            type="beta"
                            changes={[
                                {
                                    type: 'added',
                                    items: [
                                        'Added Supabase adapter',
                                        'Added conflict resolution strategies',
                                        'Added version tracking',
                                    ]
                                },
                                {
                                    type: 'fixed',
                                    items: [
                                        'Fixed Firebase adapter issues',
                                        'Fixed queue management bugs',
                                    ]
                                }
                            ]}
                            githubUrl="https://github.com/hostspicaindia/synclayer/releases/tag/v0.2.0-beta.3"
                        />

                        <Release
                            version="0.2.0-beta.2"
                            date="January 30, 2026"
                            type="beta"
                            changes={[
                                {
                                    type: 'added',
                                    items: [
                                        'Added Firebase adapter',
                                        'Added automatic retry logic',
                                        'Added offline queue',
                                    ]
                                },
                                {
                                    type: 'changed',
                                    items: [
                                        'Refactored sync engine',
                                        'Improved API design',
                                    ]
                                }
                            ]}
                            githubUrl="https://github.com/hostspicaindia/synclayer/releases/tag/v0.2.0-beta.2"
                        />

                        <Release
                            version="0.2.0-beta.1"
                            date="January 25, 2026"
                            type="beta"
                            changes={[
                                {
                                    type: 'added',
                                    items: [
                                        'Initial beta release',
                                        'Core sync functionality',
                                        'Isar-based local storage',
                                        'REST API adapter',
                                        'Basic CRUD operations',
                                    ]
                                }
                            ]}
                            githubUrl="https://github.com/hostspicaindia/synclayer/releases/tag/v0.2.0-beta.1"
                        />
                    </div>

                    <div className="mt-12 bg-blue-50 border border-blue-200 rounded-xl p-6">
                        <h2 className="text-xl font-bold text-black mb-2">Stay Updated</h2>
                        <p className="text-gray-700 mb-4">
                            Follow our GitHub repository to get notified about new releases
                        </p>
                        <a
                            href="https://github.com/hostspicaindia/synclayer/releases"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-2 px-6 py-3 bg-black text-white rounded-lg hover:bg-gray-800 transition-colors font-semibold"
                        >
                            <GithubIcon className="w-5 h-5" />
                            Watch on GitHub
                        </a>
                    </div>
                </div>
            </section>
        </div>
    );
}

function Release({
    version,
    date,
    type,
    changes,
    githubUrl
}: {
    version: string;
    date: string;
    type: 'stable' | 'beta' | 'alpha';
    changes: Array<{
        type: 'added' | 'changed' | 'fixed' | 'removed' | 'deprecated' | 'security';
        items: string[];
    }>;
    githubUrl: string;
}) {
    const typeColors = {
        stable: 'bg-green-100 text-green-700 border-green-200',
        beta: 'bg-blue-100 text-blue-700 border-blue-200',
        alpha: 'bg-yellow-100 text-yellow-700 border-yellow-200',
    };

    const changeTypeConfig = {
        added: { label: 'Added', color: 'text-green-600', emoji: '✨' },
        changed: { label: 'Changed', color: 'text-blue-600', emoji: '🔄' },
        fixed: { label: 'Fixed', color: 'text-red-600', emoji: '🐛' },
        removed: { label: 'Removed', color: 'text-gray-600', emoji: '🗑️' },
        deprecated: { label: 'Deprecated', color: 'text-orange-600', emoji: '⚠️' },
        security: { label: 'Security', color: 'text-purple-600', emoji: '🔒' },
    };

    return (
        <div className="bg-white border border-gray-200 rounded-xl p-6">
            <div className="flex items-start justify-between mb-4">
                <div>
                    <div className="flex items-center gap-3 mb-2">
                        <h2 className="text-2xl font-bold text-black">{version}</h2>
                        <span className={`text-xs px-3 py-1 rounded-full font-medium border ${typeColors[type]}`}>
                            {type}
                        </span>
                    </div>
                    <div className="flex items-center gap-2 text-sm text-gray-600">
                        <Calendar className="w-4 h-4" />
                        <span>{date}</span>
                    </div>
                </div>
                <a
                    href={githubUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 text-sm text-gray-700 hover:text-black transition-colors"
                >
                    <Tag className="w-4 h-4" />
                    View Release
                </a>
            </div>

            <div className="space-y-4">
                {changes.map((change, i) => {
                    const config = changeTypeConfig[change.type];
                    return (
                        <div key={i}>
                            <h3 className={`text-sm font-bold mb-2 flex items-center gap-2 ${config.color}`}>
                                <span>{config.emoji}</span>
                                {config.label}
                            </h3>
                            <ul className="space-y-1 ml-6">
                                {change.items.map((item, j) => (
                                    <li key={j} className="text-sm text-gray-700 list-disc">
                                        {item}
                                    </li>
                                ))}
                            </ul>
                        </div>
                    );
                })}
            </div>
        </div>
    );
}
