import type { Metadata } from 'next';
import { Mail, Github as GithubIcon, Twitter as TwitterIcon, Linkedin as LinkedinIcon, MessageSquare } from 'lucide-react';

export const metadata: Metadata = {
    title: 'Contact Us',
    description: 'Get in touch with the HostSpica team',
};

export default function ContactPage() {
    return (
        <div className="min-h-screen bg-white">
            <section className="px-6 pt-20 pb-24">
                <div className="max-w-4xl mx-auto">
                    <h1 className="text-5xl font-bold text-black mb-6">Get in Touch</h1>
                    <p className="text-xl text-gray-700 mb-12">
                        Have questions, feedback, or want to collaborate? We'd love to hear from you.
                    </p>

                    <div className="grid md:grid-cols-2 gap-8 mb-12">
                        <ContactCard
                            icon={<GithubIcon className="w-8 h-8 text-black" />}
                            title="GitHub"
                            description="Report issues, contribute code, or browse our repositories"
                            link="https://github.com/hostspicaindia"
                            linkText="Visit GitHub"
                        />
                        <ContactCard
                            icon={<TwitterIcon className="w-8 h-8 text-black" />}
                            title="Twitter"
                            description="Follow us for updates, announcements, and tech insights"
                            link="https://twitter.com/hostspicaindia"
                            linkText="Follow on Twitter"
                        />
                        <ContactCard
                            icon={<LinkedinIcon className="w-8 h-8 text-black" />}
                            title="LinkedIn"
                            description="Connect with us professionally and stay updated"
                            link="https://linkedin.com/company/hostspicaindia"
                            linkText="Connect on LinkedIn"
                        />
                        <ContactCard
                            icon={<MessageSquare className="w-8 h-8 text-black" />}
                            title="Discussions"
                            description="Join community discussions and get help from other developers"
                            link="https://github.com/hostspicaindia/synclayer/discussions"
                            linkText="Join Discussions"
                        />
                    </div>

                    <div className="bg-gray-50 border border-gray-200 rounded-2xl p-8 mb-12">
                        <h2 className="text-2xl font-bold text-black mb-4">For Business Inquiries</h2>
                        <p className="text-gray-700 mb-6">
                            Interested in enterprise support, custom development, or partnerships?
                        </p>
                        <a
                            href="https://hostspica.com"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center px-6 py-3 bg-black text-white rounded-lg hover:bg-gray-800 transition-colors font-semibold"
                        >
                            Visit HostSpica.com
                        </a>
                    </div>

                    <div className="bg-blue-50 border border-blue-200 rounded-2xl p-8">
                        <h2 className="text-2xl font-bold text-black mb-4">Need Help?</h2>
                        <p className="text-gray-700 mb-6">
                            Before reaching out, check if your question is already answered:
                        </p>
                        <div className="space-y-3">
                            <HelpLink
                                title="Documentation"
                                description="Comprehensive guides and API reference"
                                href="/docs"
                            />
                            <HelpLink
                                title="Examples"
                                description="Real-world code examples"
                                href="/docs/examples"
                            />
                            <HelpLink
                                title="GitHub Issues"
                                description="Known issues and bug reports"
                                href="https://github.com/hostspicaindia/synclayer/issues"
                                external
                            />
                            <HelpLink
                                title="Quick Start"
                                description="Get started in 5 minutes"
                                href="/docs/quick-start"
                            />
                        </div>
                    </div>
                </div>
            </section>
        </div>
    );
}

function ContactCard({
    icon,
    title,
    description,
    link,
    linkText
}: {
    icon: React.ReactNode;
    title: string;
    description: string;
    link: string;
    linkText: string;
}) {
    return (
        <div className="bg-white border border-gray-200 rounded-xl p-6 hover:border-black transition-colors">
            <div className="mb-4">{icon}</div>
            <h3 className="text-xl font-bold text-black mb-2">{title}</h3>
            <p className="text-gray-700 mb-4">{description}</p>
            <a
                href={link}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center text-black font-semibold hover:underline"
            >
                {linkText} →
            </a>
        </div>
    );
}

function HelpLink({
    title,
    description,
    href,
    external = false
}: {
    title: string;
    description: string;
    href: string;
    external?: boolean;
}) {
    return (
        <a
            href={href}
            {...(external ? { target: '_blank', rel: 'noopener noreferrer' } : {})}
            className="flex items-start justify-between p-4 bg-white border border-gray-200 rounded-lg hover:border-black transition-colors group"
        >
            <div>
                <h4 className="font-bold text-black mb-1">{title}</h4>
                <p className="text-sm text-gray-700">{description}</p>
            </div>
            <span className="text-black group-hover:translate-x-1 transition-transform">→</span>
        </a>
    );
}
