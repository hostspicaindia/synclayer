import type { Metadata } from 'next';
import Link from 'next/link';
import { Github as GithubIcon, ExternalLink } from 'lucide-react';
import { SiFlutter } from 'react-icons/si';

export const metadata: Metadata = {
    title: 'Examples',
    description: 'Example projects and applications built with HostSpica SDKs',
};

export default function ExamplesPage() {
    return (
        <div className="min-h-screen bg-white">
            <section className="px-6 pt-20 pb-24">
                <div className="max-w-6xl mx-auto">
                    <h1 className="text-5xl font-bold text-black mb-4">Example Projects</h1>
                    <p className="text-xl text-gray-700 mb-12">
                        Real-world applications and code examples built with HostSpica SDKs
                    </p>

                    <div className="grid md:grid-cols-2 gap-6 mb-12">
                        <ExampleCard
                            icon={<SiFlutter className="w-8 h-8 text-[#02569B]" />}
                            title="Todo App with SyncLayer"
                            description="A complete offline-first todo application demonstrating CRUD operations, real-time sync, and conflict resolution."
                            features={[
                                'Offline-first architecture',
                                'Real-time updates',
                                'Conflict resolution',
                                'Material Design UI'
                            ]}
                            githubUrl="https://github.com/hostspicaindia/synclayer/tree/main/example/todo"
                            platform="Flutter"
                        />

                        <ExampleCard
                            icon={<SiFlutter className="w-8 h-8 text-[#02569B]" />}
                            title="Firebase Integration"
                            description="Example showing how to integrate SyncLayer with Firebase Firestore for backend synchronization."
                            features={[
                                'Firebase authentication',
                                'Firestore integration',
                                'Real-time listeners',
                                'Cloud sync'
                            ]}
                            githubUrl="https://github.com/hostspicaindia/synclayer/tree/main/example"
                            platform="Flutter"
                        />

                        <ExampleCard
                            icon={<SiFlutter className="w-8 h-8 text-[#02569B]" />}
                            title="Supabase Integration"
                            description="Demonstrates SyncLayer integration with Supabase for PostgreSQL-backed sync."
                            features={[
                                'Supabase client',
                                'PostgreSQL backend',
                                'Row-level security',
                                'Real-time subscriptions'
                            ]}
                            githubUrl="https://github.com/hostspicaindia/synclayer/tree/main/example"
                            platform="Flutter"
                        />

                        <ExampleCard
                            icon={<SiFlutter className="w-8 h-8 text-[#02569B]" />}
                            title="Custom Backend Adapter"
                            description="Learn how to create a custom backend adapter for your own API."
                            features={[
                                'Custom REST API',
                                'Authentication handling',
                                'Error management',
                                'Retry logic'
                            ]}
                            githubUrl="https://github.com/hostspicaindia/synclayer/tree/main/example"
                            platform="Flutter"
                        />
                    </div>

                    <div className="bg-gray-50 border border-gray-200 rounded-2xl p-8 mb-12">
                        <h2 className="text-2xl font-bold text-black mb-4">Code Snippets</h2>
                        <p className="text-gray-700 mb-6">
                            Looking for quick code examples? Check out our documentation for inline code snippets and usage patterns.
                        </p>
                        <Link
                            href="/docs/examples"
                            className="inline-flex items-center text-black font-semibold hover:underline"
                        >
                            View Code Examples →
                        </Link>
                    </div>

                    <div className="bg-blue-50 border border-blue-200 rounded-2xl p-8">
                        <h2 className="text-2xl font-bold text-black mb-4">Contribute Your Example</h2>
                        <p className="text-gray-700 mb-6">
                            Built something cool with our SDKs? We'd love to feature your project! Submit a pull request or open an issue on GitHub.
                        </p>
                        <a
                            href="https://github.com/hostspicaindia/synclayer/issues/new"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-2 px-6 py-3 bg-black text-white rounded-lg hover:bg-gray-800 transition-colors font-semibold"
                        >
                            <GithubIcon className="w-5 h-5" />
                            Submit on GitHub
                        </a>
                    </div>
                </div>
            </section>
        </div>
    );
}

function ExampleCard({
    icon,
    title,
    description,
    features,
    githubUrl,
    platform
}: {
    icon: React.ReactNode;
    title: string;
    description: string;
    features: string[];
    githubUrl: string;
    platform: string;
}) {
    return (
        <div className="bg-white border border-gray-200 rounded-2xl p-6 hover:border-black transition-colors">
            <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                    {icon}
                    <span className="text-xs px-3 py-1 bg-gray-100 text-gray-700 rounded-full font-medium">
                        {platform}
                    </span>
                </div>
            </div>

            <h3 className="text-xl font-bold text-black mb-2">{title}</h3>
            <p className="text-gray-700 mb-4">{description}</p>

            <div className="mb-4">
                <h4 className="text-sm font-semibold text-black mb-2">Features:</h4>
                <ul className="space-y-1">
                    {features.map((feature, i) => (
                        <li key={i} className="text-sm text-gray-700 flex items-start gap-2">
                            <span className="text-green-600 mt-0.5">✓</span>
                            {feature}
                        </li>
                    ))}
                </ul>
            </div>

            <a
                href={githubUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 text-black font-semibold hover:underline"
            >
                <GithubIcon className="w-4 h-4" />
                View on GitHub
                <ExternalLink className="w-4 h-4" />
            </a>
        </div>
    );
}
