import type { Metadata } from 'next';
import Link from 'next/link';
import { Code2, Users, Target, Zap, Heart, Globe } from 'lucide-react';

export const metadata: Metadata = {
    title: 'About Us',
    description: 'Learn about HostSpica and our mission to build enterprise-grade SDKs',
};

export default function AboutPage() {
    return (
        <div className="min-h-screen bg-white">
            <section className="px-6 pt-20 pb-24">
                <div className="max-w-4xl mx-auto">
                    <h1 className="text-5xl font-bold text-black mb-6">About HostSpica</h1>
                    <p className="text-2xl text-gray-700 mb-12 leading-relaxed">
                        We build enterprise-grade SDKs that empower developers to create better applications faster.
                    </p>

                    <div className="prose prose-lg max-w-none">
                        <Section title="Our Mission">
                            <p className="text-gray-700 mb-4">
                                At HostSpica, we believe that developers deserve better tools. Our mission is to create
                                production-ready SDKs that eliminate boilerplate, reduce development time, and provide
                                enterprise-grade features out of the box.
                            </p>
                            <p className="text-gray-700">
                                We're committed to open source, comprehensive documentation, and building tools that
                                developers actually want to use.
                            </p>
                        </Section>

                        <Section title="What We Do">
                            <div className="grid md:grid-cols-2 gap-6 my-8">
                                <ValueCard
                                    icon={<Code2 className="w-8 h-8 text-black" />}
                                    title="Build SDKs"
                                    description="We create production-ready software development kits for multiple platforms including Flutter, JavaScript, Python, and more."
                                />
                                <ValueCard
                                    icon={<Users className="w-8 h-8 text-black" />}
                                    title="Support Developers"
                                    description="We provide comprehensive documentation, examples, and active support to help developers succeed."
                                />
                                <ValueCard
                                    icon={<Target className="w-8 h-8 text-black" />}
                                    title="Solve Real Problems"
                                    description="Every SDK we build addresses real-world challenges faced by developers in production environments."
                                />
                                <ValueCard
                                    icon={<Zap className="w-8 h-8 text-black" />}
                                    title="Optimize Performance"
                                    description="We obsess over performance, ensuring our SDKs are fast, efficient, and production-ready."
                                />
                            </div>
                        </Section>

                        <Section title="Our Values">
                            <div className="space-y-6 my-8">
                                <Value
                                    icon={<Heart className="w-6 h-6 text-red-600" />}
                                    title="Developer First"
                                    description="Every decision we make prioritizes developer experience. Clean APIs, great documentation, and intuitive design are non-negotiable."
                                />
                                <Value
                                    icon={<Globe className="w-6 h-6 text-blue-600" />}
                                    title="Open Source"
                                    description="We believe in the power of open source. All our SDKs are open source and MIT licensed, giving you complete freedom."
                                />
                                <Value
                                    icon={<Target className="w-6 h-6 text-green-600" />}
                                    title="Production Ready"
                                    description="We don't ship prototypes. Every SDK is battle-tested, well-documented, and ready for production use from day one."
                                />
                            </div>
                        </Section>

                        <Section title="Our Products">
                            <div className="bg-gray-50 border border-gray-200 rounded-2xl p-8 my-8">
                                <h3 className="text-2xl font-bold text-black mb-4">SyncLayer</h3>
                                <p className="text-gray-700 mb-4">
                                    Our flagship Flutter SDK for building offline-first applications. SyncLayer provides
                                    automatic synchronization, conflict resolution, and real-time updates with a clean,
                                    type-safe API.
                                </p>
                                <div className="flex flex-wrap gap-3">
                                    <Link
                                        href="/flutter/synclayer"
                                        className="inline-flex items-center text-black font-semibold hover:underline"
                                    >
                                        Learn More →
                                    </Link>
                                    <a
                                        href="https://pub.dev/packages/synclayer"
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="inline-flex items-center text-gray-700 hover:text-black transition-colors font-medium"
                                    >
                                        View on pub.dev
                                    </a>
                                </div>
                            </div>

                            <p className="text-gray-700 italic">
                                More SDKs coming soon for NPM, Python, Go, Rust, and .NET platforms.
                            </p>
                        </Section>

                        <Section title="Get Involved">
                            <p className="text-gray-700 mb-6">
                                We're building HostSpica in the open and welcome contributions from the community.
                            </p>
                            <div className="grid md:grid-cols-2 gap-4">
                                <InvolvementCard
                                    title="Contribute on GitHub"
                                    description="Submit issues, pull requests, or help improve documentation"
                                    href="https://github.com/hostspicaindia"
                                />
                                <InvolvementCard
                                    title="Follow Our Journey"
                                    description="Stay updated on Twitter and LinkedIn"
                                    href="https://twitter.com/hostspicaindia"
                                />
                                <InvolvementCard
                                    title="Report Issues"
                                    description="Found a bug? Let us know on GitHub"
                                    href="https://github.com/hostspicaindia/synclayer/issues"
                                />
                                <InvolvementCard
                                    title="Contact Us"
                                    description="Have questions? Get in touch"
                                    href="/contact"
                                />
                            </div>
                        </Section>

                        <div className="bg-black text-white rounded-2xl p-8 mt-12 text-center">
                            <h2 className="text-3xl font-bold mb-4">Ready to Build?</h2>
                            <p className="text-gray-300 mb-6 max-w-2xl mx-auto">
                                Start using our SDKs today and join developers building the next generation of applications.
                            </p>
                            <div className="flex flex-col sm:flex-row gap-4 justify-center">
                                <Link
                                    href="/flutter"
                                    className="inline-flex items-center justify-center px-8 py-4 bg-white text-black rounded-full hover:bg-gray-100 transition-colors font-semibold"
                                >
                                    Explore SDKs
                                </Link>
                                <Link
                                    href="/docs"
                                    className="inline-flex items-center justify-center px-8 py-4 border-2 border-white text-white rounded-full hover:bg-white hover:text-black transition-colors font-semibold"
                                >
                                    Read Documentation
                                </Link>
                            </div>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
    return (
        <div className="mb-12">
            <h2 className="text-3xl font-bold text-black mb-6">{title}</h2>
            {children}
        </div>
    );
}

function ValueCard({
    icon,
    title,
    description
}: {
    icon: React.ReactNode;
    title: string;
    description: string;
}) {
    return (
        <div className="bg-white border border-gray-200 rounded-xl p-6">
            <div className="mb-4">{icon}</div>
            <h3 className="text-xl font-bold text-black mb-2">{title}</h3>
            <p className="text-gray-700">{description}</p>
        </div>
    );
}

function Value({
    icon,
    title,
    description
}: {
    icon: React.ReactNode;
    title: string;
    description: string;
}) {
    return (
        <div className="flex gap-4">
            <div className="flex-shrink-0">{icon}</div>
            <div>
                <h3 className="text-xl font-bold text-black mb-2">{title}</h3>
                <p className="text-gray-700">{description}</p>
            </div>
        </div>
    );
}

function InvolvementCard({
    title,
    description,
    href
}: {
    title: string;
    description: string;
    href: string;
}) {
    const isExternal = href.startsWith('http');
    const content = (
        <div className="block p-4 bg-gray-50 border border-gray-200 rounded-lg hover:border-black transition-colors">
            <h3 className="font-bold text-black mb-1">{title}</h3>
            <p className="text-sm text-gray-700">{description}</p>
        </div>
    );

    return isExternal ? (
        <a href={href} target="_blank" rel="noopener noreferrer">
            {content}
        </a>
    ) : (
        <Link href={href}>{content}</Link>
    );
}
