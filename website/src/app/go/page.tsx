import type { Metadata } from 'next';
import Link from 'next/link';
import { SiGo } from 'react-icons/si';
import { ArrowLeft, Bell } from 'lucide-react';

export const metadata: Metadata = {
    title: 'Go SDKs',
    description: 'Go modules and packages from HostSpica - Coming Soon',
};

export default function GoPage() {
    return (
        <div className="min-h-screen bg-white">
            <section className="px-6 pt-20 pb-24">
                <div className="max-w-4xl mx-auto text-center">
                    <Link
                        href="/"
                        className="inline-flex items-center text-gray-700 hover:text-black mb-8 transition-colors"
                    >
                        <ArrowLeft className="w-4 h-4 mr-2" />
                        Back to Home
                    </Link>

                    <SiGo className="w-24 h-24 text-[#00ADD8] mx-auto mb-8" />

                    <h1 className="text-5xl font-bold text-black mb-4">Go SDKs</h1>
                    <p className="text-xl text-gray-700 mb-8">
                        High-performance Go modules and packages
                    </p>

                    <div className="inline-flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-800 rounded-full text-sm font-medium mb-12">
                        <Bell className="w-4 h-4" />
                        Coming Soon
                    </div>

                    <div className="bg-gray-50 border border-gray-200 rounded-2xl p-8 mb-8 text-left">
                        <h2 className="text-2xl font-bold text-black mb-4">What to Expect</h2>
                        <ul className="space-y-3 text-gray-700">
                            <li className="flex items-start gap-3">
                                <span className="text-[#00ADD8] mt-1">•</span>
                                <span>Production-ready Go modules with comprehensive testing</span>
                            </li>
                            <li className="flex items-start gap-3">
                                <span className="text-[#00ADD8] mt-1">•</span>
                                <span>Clean, idiomatic Go code following best practices</span>
                            </li>
                            <li className="flex items-start gap-3">
                                <span className="text-[#00ADD8] mt-1">•</span>
                                <span>Full documentation and examples</span>
                            </li>
                            <li className="flex items-start gap-3">
                                <span className="text-[#00ADD8] mt-1">•</span>
                                <span>Performance-optimized for concurrent workloads</span>
                            </li>
                        </ul>
                    </div>

                    <div className="flex flex-col sm:flex-row gap-4 justify-center">
                        <a
                            href="https://github.com/hostspicaindia"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="inline-flex items-center justify-center px-8 py-4 bg-black text-white rounded-full hover:bg-gray-800 transition-colors font-semibold"
                        >
                            Follow on GitHub
                        </a>
                        <Link
                            href="/flutter"
                            className="inline-flex items-center justify-center px-8 py-4 border-2 border-gray-300 text-black rounded-full hover:border-black transition-colors font-semibold"
                        >
                            Explore Flutter SDKs
                        </Link>
                    </div>
                </div>
            </section>
        </div>
    );
}
