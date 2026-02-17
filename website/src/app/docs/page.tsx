import type { Metadata } from 'next';
import Link from 'next/link';
import { Book, Rocket, Code2, FileText, Layers, Zap } from 'lucide-react';

export const metadata: Metadata = {
    title: 'Documentation',
    description: 'Comprehensive documentation for HostSpica SDKs',
};

export default function DocsPage() {
    return (
        <div className="min-h-screen bg-white">
            <section className="px-6 pt-20 pb-24">
                <div className="max-w-6xl mx-auto">
                    <div className="text-center mb-16">
                        <h1 className="text-5xl font-bold text-black mb-4">Documentation</h1>
                        <p className="text-xl text-gray-700 max-w-2xl mx-auto">
                            Everything you need to build with HostSpica SDKs
                        </p>
                    </div>

                    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
                        <DocCard
                            icon={<Rocket className="w-8 h-8 text-black" />}
                            title="Quick Start"
                            description="Get up and running in minutes with our step-by-step guides"
                            href="/docs/quick-start"
                        />
                        <DocCard
                            icon={<Layers className="w-8 h-8 text-black" />}
                            title="Architecture"
                            description="Understand the technical architecture and design patterns"
                            href="/docs/architecture"
                        />
                        <DocCard
                            icon={<Code2 className="w-8 h-8 text-black" />}
                            title="API Reference"
                            description="Complete API documentation with examples"
                            href="/docs/api"
                        />
                        <DocCard
                            icon={<FileText className="w-8 h-8 text-black" />}
                            title="Examples"
                            description="Real-world code examples and use cases"
                            href="/docs/examples"
                        />
                        <DocCard
                            icon={<Book className="w-8 h-8 text-black" />}
                            title="Guides"
                            description="In-depth guides for advanced features"
                            href="/docs/guides"
                            comingSoon
                        />
                        <DocCard
                            icon={<Zap className="w-8 h-8 text-black" />}
                            title="Best Practices"
                            description="Tips and best practices for production apps"
                            href="/docs/best-practices"
                            comingSoon
                        />
                    </div>

                    <div className="mt-16 bg-gray-50 rounded-2xl p-8 border border-gray-200">
                        <h2 className="text-2xl font-bold text-black mb-4">SDK Documentation</h2>
                        <p className="text-gray-700 mb-6">
                            Browse documentation for specific SDKs
                        </p>
                        <div className="space-y-3">
                            <SDKLink
                                name="SyncLayer (Flutter)"
                                description="Local-first sync engine for Flutter"
                                href="/flutter/synclayer"
                            />
                            <SDKLink
                                name="More SDKs Coming Soon"
                                description="NPM, Python, Go, Rust, and .NET packages"
                                href="/"
                                disabled
                            />
                        </div>
                    </div>
                </div>
            </section>
        </div>
    );
}

function DocCard({
    icon,
    title,
    description,
    href,
    comingSoon = false
}: {
    icon: React.ReactNode;
    title: string;
    description: string;
    href: string;
    comingSoon?: boolean;
}) {
    const content = (
        <div className={`group p-6 bg-white border rounded-2xl transition-all h-full ${comingSoon
                ? 'border-gray-200 opacity-60'
                : 'border-gray-300 hover:border-black hover:shadow-sm cursor-pointer'
            }`}>
            <div className="mb-4">{icon}</div>
            <div className="flex items-center justify-between mb-2">
                <h3 className="text-xl font-bold text-black">{title}</h3>
                {comingSoon && (
                    <span className="text-xs px-3 py-1 bg-gray-100 text-gray-600 rounded-full font-medium">
                        Coming Soon
                    </span>
                )}
            </div>
            <p className="text-gray-700">{description}</p>
        </div>
    );

    return comingSoon ? <div>{content}</div> : <Link href={href}>{content}</Link>;
}

function SDKLink({
    name,
    description,
    href,
    disabled = false
}: {
    name: string;
    description: string;
    href: string;
    disabled?: boolean;
}) {
    const content = (
        <div className={`flex items-center justify-between p-4 rounded-lg border transition-colors ${disabled
                ? 'border-gray-200 bg-gray-50 opacity-60'
                : 'border-gray-200 hover:border-black bg-white cursor-pointer'
            }`}>
            <div>
                <div className="font-semibold text-black">{name}</div>
                <div className="text-sm text-gray-600">{description}</div>
            </div>
            {!disabled && (
                <span className="text-black">→</span>
            )}
        </div>
    );

    return disabled ? <div>{content}</div> : <Link href={href}>{content}</Link>;
}
