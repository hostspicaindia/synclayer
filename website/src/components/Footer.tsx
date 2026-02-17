import Link from 'next/link';
import { Github as GithubIcon, Twitter as TwitterIcon, Linkedin as LinkedinIcon } from 'lucide-react';
import Image from 'next/image';

export default function Footer() {
    return (
        <footer className="bg-black text-white py-12">
            <div className="px-6">
                <div className="max-w-7xl mx-auto">
                    <div className="grid md:grid-cols-5 gap-8 mb-8">
                        <div className="md:col-span-2">
                            <div className="flex items-center space-x-2 mb-3">
                                <Image src="/logo.png" alt="HostSpica" width={20} height={20} className="w-5 h-5" />
                                <span className="text-base font-semibold text-white">HostSpica SDK</span>
                            </div>
                            <p className="text-gray-400 text-sm mb-4 max-w-sm">
                                Enterprise-grade SDKs and libraries for modern development.
                            </p>
                            <div className="flex items-center gap-3">
                                <a
                                    href="https://github.com/hostspicaindia"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="text-gray-400 hover:text-white transition-colors"
                                    aria-label="GitHub"
                                >
                                    <GithubIcon className="w-4 h-4" />
                                </a>
                                <a
                                    href="https://twitter.com/hostspicaindia"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="text-gray-400 hover:text-white transition-colors"
                                    aria-label="Twitter"
                                >
                                    <TwitterIcon className="w-4 h-4" />
                                </a>
                                <a
                                    href="https://linkedin.com/company/hostspicaindia"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="text-gray-400 hover:text-white transition-colors"
                                    aria-label="LinkedIn"
                                >
                                    <LinkedinIcon className="w-4 h-4" />
                                </a>
                            </div>
                        </div>

                        <div>
                            <h4 className="font-medium text-white mb-3 text-sm">Platforms</h4>
                            <ul className="space-y-2 text-sm">
                                <li><Link href="/flutter" className="text-gray-400 hover:text-white transition-colors">Flutter</Link></li>
                                <li><Link href="/npm" className="text-gray-400 hover:text-white transition-colors">NPM</Link></li>
                                <li><Link href="/python" className="text-gray-400 hover:text-white transition-colors">Python</Link></li>
                                <li><Link href="/go" className="text-gray-400 hover:text-white transition-colors">Go</Link></li>
                            </ul>
                        </div>

                        <div>
                            <h4 className="font-medium text-white mb-3 text-sm">Resources</h4>
                            <ul className="space-y-2 text-sm">
                                <li><a href="https://github.com/hostspicaindia" className="text-gray-400 hover:text-white transition-colors">GitHub</a></li>
                                <li><Link href="/docs" className="text-gray-400 hover:text-white transition-colors">Documentation</Link></li>
                                <li><Link href="/examples" className="text-gray-400 hover:text-white transition-colors">Examples</Link></li>
                                <li><Link href="/blog" className="text-gray-400 hover:text-white transition-colors">Blog</Link></li>
                                <li><Link href="/changelog" className="text-gray-400 hover:text-white transition-colors">Changelog</Link></li>
                            </ul>
                        </div>

                        <div>
                            <h4 className="font-medium text-white mb-3 text-sm">Company</h4>
                            <ul className="space-y-2 text-sm">
                                <li><a href="https://hostspica.com" className="text-gray-400 hover:text-white transition-colors">HostSpica</a></li>
                                <li><Link href="/about" className="text-gray-400 hover:text-white transition-colors">About</Link></li>
                                <li><Link href="/contact" className="text-gray-400 hover:text-white transition-colors">Contact</Link></li>
                            </ul>
                        </div>
                    </div>

                    <div className="border-t border-gray-800 pt-6 flex flex-col md:flex-row justify-between items-center gap-4">
                        <p className="text-xs text-gray-400">
                            © 2026 HostSpica. All rights reserved.
                        </p>
                        <div className="flex items-center gap-6 text-xs text-gray-400">
                            <Link href="/privacy" className="hover:text-white transition-colors">Privacy</Link>
                            <Link href="/terms" className="hover:text-white transition-colors">Terms</Link>
                        </div>
                    </div>
                </div>
            </div>
        </footer>
    );
}
