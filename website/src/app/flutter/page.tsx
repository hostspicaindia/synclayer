import Link from 'next/link';
import { ArrowRight } from 'lucide-react';
import { SiFlutter } from 'react-icons/si';

export default function FlutterSDKs() {
    return (
        <div className="min-h-screen bg-white">
            {/* Hero Section */}
            <section className="px-6 pt-24 pb-16">
                <div className="max-w-4xl mx-auto text-center">
                    <div className="inline-flex items-center gap-2 px-3 py-1 bg-gray-100 text-gray-800 rounded-full text-xs font-medium mb-6">
                        <SiFlutter className="w-3 h-3 text-[#02569B]" />
                        <span>Flutter Platform</span>
                    </div>

                    <h1 className="text-5xl md:text-6xl font-bold mb-6 leading-tight text-black">
                        Flutter SDKs for Mobile & Cross-Platform
                    </h1>

                    <p className="text-lg text-gray-700 mb-12 max-w-2xl mx-auto leading-relaxed">
                        Production-ready Flutter packages and SDKs for building modern mobile applications.
                        Enterprise-grade, well-documented, and battle-tested.
                    </p>
                </div>
            </section>

            {/* Available SDKs */}
            <section className="px-6 py-16">
                <div className="max-w-6xl mx-auto">
                    <h2 className="text-3xl font-bold text-black mb-12">Available SDKs</h2>

                    <div className="bg-white border border-gray-200 rounded-2xl p-8">
                        <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-6">
                            <div className="flex-1">
                                <div className="flex items-center gap-3 mb-3">
                                    <SiFlutter className="w-6 h-6 text-[#02569B]" />
                                    <h3 className="text-2xl font-bold text-black">SyncLayer</h3>
                                    <span className="px-3 py-1 bg-gray-100 text-gray-800 rounded-full text-xs font-medium">
                                        Flutter
                                    </span>
                                </div>
                                <div className="flex items-center gap-3 mb-4">
                                    <span className="text-sm text-gray-600 font-mono">v0.2.0-beta.5</span>
                                    <span className="text-gray-300">•</span>
                                    <span className="text-sm text-green-600 font-medium">Production Ready</span>
                                </div>
                                <p className="text-gray-700 mb-6 leading-relaxed">
                                    Enterprise-grade local-first sync engine with offline support, conflict resolution, and real-time updates.
                                    Built with Isar, powered by event-driven architecture.
                                </p>

                                <div className="grid grid-cols-2 gap-3 mb-6">
                                    {[
                                        'Offline-First Architecture',
                                        'Auto-Sync & Conflict Resolution',
                                        'Backend Agnostic (REST, Firebase, Supabase)',
                                        'Event-Driven System',
                                        'Isar-Powered Storage',
                                        'Type-Safe API'
                                    ].map((feature, i) => (
                                        <div key={i} className="flex items-center gap-2 text-sm text-gray-700">
                                            <div className="w-1.5 h-1.5 rounded-full bg-black" />
                                            {feature}
                                        </div>
                                    ))}
                                </div>

                                <div className="flex flex-wrap gap-2 mb-6">
                                    {['Sync', 'Offline-First', 'Local Storage', 'Real-time'].map((tag, i) => (
                                        <span key={i} className="text-xs px-3 py-1 bg-gray-100 text-gray-700 rounded-full font-medium">
                                            {tag}
                                        </span>
                                    ))}
                                </div>

                                <div className="flex flex-wrap gap-4">
                                    <Link
                                        href="/flutter/synclayer"
                                        className="inline-flex items-center text-black font-semibold hover:gap-3 transition-all"
                                    >
                                        View Documentation <ArrowRight className="ml-2 w-4 h-4" />
                                    </Link>
                                    <a
                                        href="https://pub.dev/packages/synclayer"
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="inline-flex items-center text-gray-700 hover:text-black transition-colors font-medium"
                                    >
                                        pub.dev
                                    </a>
                                    <a
                                        href="https://github.com/hostspicaindia/synclayer"
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="inline-flex items-center text-gray-700 hover:text-black transition-colors font-medium"
                                    >
                                        GitHub
                                    </a>
                                </div>
                            </div>

                            <div className="grid grid-cols-2 md:grid-cols-1 gap-4 md:min-w-[180px]">
                                <MetricBox label="Package Size" value="312 KB" />
                                <MetricBox label="Tests" value="48 Passing" />
                                <MetricBox label="Pub Score" value="160/160" />
                                <MetricBox label="Platforms" value="5" />
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            {/* Coming Soon */}
            <section className="px-6 py-16 bg-gray-50">
                <div className="max-w-6xl mx-auto">
                    <h2 className="text-3xl font-bold text-black mb-12">Coming Soon</h2>

                    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
                        <ComingSoonCard
                            name="AuthLayer"
                            description="Complete authentication solution with biometric support, OAuth, and session management"
                            category="Authentication"
                        />
                        <ComingSoonCard
                            name="CacheLayer"
                            description="Advanced caching system with TTL, LRU eviction, and memory management"
                            category="Caching"
                        />
                        <ComingSoonCard
                            name="NetworkLayer"
                            description="HTTP client with retry logic, interceptors, and request/response transformation"
                            category="Networking"
                        />
                        <ComingSoonCard
                            name="StateLayer"
                            description="Reactive state management with time-travel debugging and persistence"
                            category="State Management"
                        />
                        <ComingSoonCard
                            name="AnalyticsLayer"
                            description="Privacy-focused analytics with event tracking and user insights"
                            category="Analytics"
                        />
                        <ComingSoonCard
                            name="StorageLayer"
                            description="Secure local storage with encryption and cloud backup"
                            category="Storage"
                        />
                    </div>
                </div>
            </section>

            {/* CTA */}
            <section className="px-6 py-20">
                <div className="max-w-4xl mx-auto text-center">
                    <h2 className="text-4xl font-bold text-black mb-4">Start Building with Flutter</h2>
                    <p className="text-lg text-gray-700 mb-8">
                        Explore our SDKs and accelerate your Flutter development
                    </p>
                    <div className="flex flex-col sm:flex-row gap-4 justify-center">
                        <Link
                            href="/flutter/synclayer"
                            className="inline-flex items-center justify-center px-8 py-4 bg-black text-white rounded-full hover:bg-gray-800 transition-colors font-medium"
                        >
                            Explore SyncLayer <ArrowRight className="ml-2 w-5 h-5" />
                        </Link>
                        <a
                            href="https://github.com/hostspicaindia"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center justify-center px-8 py-4 border-2 border-gray-300 text-black rounded-full hover:border-black transition-colors font-medium"
                        >
                            View on GitHub
                        </a>
                    </div>
                </div>
            </section>
        </div>
    );
}

function MetricBox({ label, value }: { label: string; value: string }) {
    return (
        <div className="text-center md:text-right">
            <div className="text-xl font-bold text-black">{value}</div>
            <div className="text-xs text-gray-600">{label}</div>
        </div>
    );
}

function ComingSoonCard({
    name,
    description,
    category
}: {
    name: string;
    description: string;
    category: string;
}) {
    return (
        <div className="p-6 bg-white border border-gray-200 rounded-xl opacity-60">
            <div className="flex items-center justify-between mb-3">
                <h3 className="text-lg font-bold text-black">{name}</h3>
                <span className="text-xs px-2 py-1 bg-gray-100 text-gray-600 rounded font-medium">Coming Soon</span>
            </div>
            <p className="text-sm text-gray-700 mb-4 leading-relaxed">{description}</p>
            <span className="text-xs px-3 py-1 bg-gray-100 text-gray-700 rounded-full font-medium">
                {category}
            </span>
        </div>
    );
}
