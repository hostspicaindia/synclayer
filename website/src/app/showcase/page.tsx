import type { Metadata } from 'next';
import Link from 'next/link';
import { ExternalLink, Github as GithubIcon, Globe } from 'lucide-react';
import { SiFlutter } from 'react-icons/si';

export const metadata: Metadata = {
    title: 'Community Showcase',
    description: 'Apps and projects built with HostSpica SDKs',
};

interface ShowcaseApp {
    name: string;
    description: string;
    platform: string;
    icon: React.ReactNode;
    features: string[];
    githubUrl?: string;
    websiteUrl?: string;
    author: string;
}

const showcaseApps: ShowcaseApp[] = [
    {
        name: 'TaskFlow Pro',
        description: 'A professional task management app with offline-first capabilities and team collaboration features.',
        platform: 'Flutter',
        icon: <SiFlutter className="w-8 h-8 text-[#02569B]" />,
        features: ['Offline sync', 'Team collaboration', 'Real-time updates', 'Cross-platform'],
        githubUrl: 'https://github.com/example/taskflow',
        websiteUrl: 'https://taskflow.example.com',
        author: 'TaskFlow Team',
    },
    {
        name: 'NoteSync',
        description: 'A minimalist note-taking app that syncs seamlessly across all your devices.',
        platform: 'Flutter',
        icon: <SiFlutter className="w-8 h-8 text-[#02569B]" />,
        features: ['Markdown support', 'Auto-sync', 'Encryption', 'Tags & search'],
        githubUrl: 'https://github.com/example/notesync',
        author: 'John Developer',
    },
    {
        name: 'InventoryHub',
        description: 'Inventory management system for small businesses with offline support.',
        platform: 'Flutter',
        icon: <SiFlutter className="w-8 h-8 text-[#02569B]" />,
        features: ['Barcode scanning', 'Stock tracking', 'Reports', 'Multi-location'],
        websiteUrl: 'https://inventoryhub.example.com',
        author: 'Business Solutions Inc',
    },
];

export default function ShowcasePage() {
    return (
        <div className="min-h-screen bg-white">
            <section className="px-6 pt-20 pb-24">
                <div className="max-w-6xl mx-auto">
                    <h1 className="text-5xl font-bold text-black mb-4">Community Showcase</h1>
                    <p className="text-xl text-gray-700 mb-12">
                        Amazing apps and projects built by our community using HostSpica SDKs
                    </p>

                    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6 mb-12">
                        {showcaseApps.map((app, i) => (
                            <ShowcaseCard key={i} {...app} />
                        ))}
                    </div>

                    <div className="bg-gradient-to-r from-blue-50 to-purple-50 border border-blue-200 rounded-2xl p-8 text-center">
                        <h2 className="text-3xl font-bold text-black mb-4">Submit Your Project</h2>
                        <p className="text-gray-700 mb-6 max-w-2xl mx-auto">
                            Built something awesome with our SDKs? We'd love to feature your project in our showcase!
                        </p>
                        <div className="flex flex-col sm:flex-row gap-4 justify-center">
                            <a
                                href="https://github.com/hostspicaindia/synclayer/discussions/new?category=show-and-tell"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="inline-flex items-center justify-center gap-2 px-8 py-4 bg-black text-white rounded-full hover:bg-gray-800 transition-colors font-semibold"
                            >
                                <GithubIcon className="w-5 h-5" />
                                Submit on GitHub
                            </a>
                            <Link
                                href="/contact"
                                className="inline-flex items-center justify-center px-8 py-4 border-2 border-gray-300 text-black rounded-full hover:border-black transition-colors font-semibold"
                            >
                                Contact Us
                            </Link>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    );
}

function ShowcaseCard({
    name,
    description,
    platform,
    icon,
    features,
    githubUrl,
    websiteUrl,
    author
}: ShowcaseApp) {
    return (
        <div className="bg-white border border-gray-200 rounded-2xl p-6 hover:border-black transition-colors flex flex-col">
            <div className="flex items-start justify-between mb-4">
                {icon}
                <span className="text-xs px-3 py-1 bg-gray-100 text-gray-700 rounded-full font-medium">
                    {platform}
                </span>
            </div>

            <h3 className="text-xl font-bold text-black mb-2">{name}</h3>
            <p className="text-gray-700 mb-4 flex-grow">{description}</p>

            <div className="mb-4">
                <h4 className="text-sm font-semibold text-black mb-2">Features:</h4>
                <div className="flex flex-wrap gap-2">
                    {features.map((feature, i) => (
                        <span
                            key={i}
                            className="text-xs px-2 py-1 bg-blue-50 text-blue-700 rounded border border-blue-200"
                        >
                            {feature}
                        </span>
                    ))}
                </div>
            </div>

            <div className="pt-4 border-t border-gray-200">
                <div className="text-sm text-gray-600 mb-3">By {author}</div>
                <div className="flex gap-3">
                    {githubUrl && (
                        <a
                            href={githubUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-1 text-sm text-gray-700 hover:text-black transition-colors"
                        >
                            <GithubIcon className="w-4 h-4" />
                            Code
                        </a>
                    )}
                    {websiteUrl && (
                        <a
                            href={websiteUrl}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center gap-1 text-sm text-gray-700 hover:text-black transition-colors"
                        >
                            <Globe className="w-4 h-4" />
                            Website
                        </a>
                    )}
                </div>
            </div>
        </div>
    );
}
