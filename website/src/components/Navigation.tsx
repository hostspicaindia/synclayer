'use client';

import Link from 'next/link';
import { useState, useEffect } from 'react';
import { Menu, X } from 'lucide-react';
import Image from 'next/image';
import Search from './Search';

export default function Navigation() {
    const [isOpen, setIsOpen] = useState(false);
    const [scrolled, setScrolled] = useState(false);

    // Close mobile menu when route changes
    useEffect(() => {
        setIsOpen(false);
    }, []);

    // Add shadow on scroll
    useEffect(() => {
        const handleScroll = () => {
            setScrolled(window.scrollY > 10);
        };
        window.addEventListener('scroll', handleScroll);
        return () => window.removeEventListener('scroll', handleScroll);
    }, []);

    // Prevent body scroll when mobile menu is open
    useEffect(() => {
        if (isOpen) {
            document.body.style.overflow = 'hidden';
        } else {
            document.body.style.overflow = 'unset';
        }
        return () => {
            document.body.style.overflow = 'unset';
        };
    }, [isOpen]);

    return (
        <nav className={`bg-white border-b sticky top-0 z-50 transition-shadow ${scrolled ? 'border-gray-200 shadow-sm' : 'border-gray-200'
            }`}>
            <div className="px-6">
                <div className="max-w-7xl mx-auto">
                    <div className="flex justify-between items-center h-16">
                        <Link href="/" className="flex items-center space-x-2" onClick={() => setIsOpen(false)}>
                            <Image src="/logo.png" alt="HostSpica" width={32} height={32} className="w-8 h-8" />
                            <div>
                                <span className="text-lg font-semibold text-black">HostSpica</span>
                                <span className="block text-xs text-gray-600">SDK Platform</span>
                            </div>
                        </Link>

                        {/* Desktop Navigation */}
                        <div className="hidden md:flex items-center space-x-8">
                            <Link href="/flutter" className="text-gray-700 hover:text-black transition-colors text-sm font-medium">
                                Flutter
                            </Link>
                            <Link href="/npm" className="text-gray-700 hover:text-black transition-colors text-sm font-medium">
                                NPM
                            </Link>
                            <Link href="/python" className="text-gray-700 hover:text-black transition-colors text-sm font-medium">
                                Python
                            </Link>
                            <Link href="/docs" className="text-gray-700 hover:text-black transition-colors text-sm font-medium">
                                Docs
                            </Link>
                            <a
                                href="https://github.com/hostspicaindia"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="text-gray-700 hover:text-black transition-colors text-sm font-medium"
                            >
                                GitHub
                            </a>
                            <Search />
                            <Link
                                href="/flutter/synclayer"
                                className="px-5 py-2 bg-black text-white rounded-full hover:bg-gray-800 transition-colors text-sm font-medium"
                            >
                                Get Started →
                            </Link>
                        </div>

                        {/* Mobile Menu Button */}
                        <button
                            className="md:hidden text-black p-2 hover:bg-gray-100 rounded-lg transition-colors"
                            onClick={() => setIsOpen(!isOpen)}
                            aria-label="Toggle menu"
                        >
                            {isOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
                        </button>
                    </div>

                    {/* Mobile Navigation */}
                    {isOpen && (
                        <div className="md:hidden fixed inset-0 top-16 bg-white z-40 overflow-y-auto">
                            <div className="py-4 space-y-1 px-6">
                                <MobileNavLink href="/flutter" onClick={() => setIsOpen(false)}>
                                    Flutter
                                </MobileNavLink>
                                <MobileNavLink href="/npm" onClick={() => setIsOpen(false)}>
                                    NPM
                                </MobileNavLink>
                                <MobileNavLink href="/python" onClick={() => setIsOpen(false)}>
                                    Python
                                </MobileNavLink>
                                <MobileNavLink href="/docs" onClick={() => setIsOpen(false)}>
                                    Documentation
                                </MobileNavLink>
                                <MobileNavLink href="/examples" onClick={() => setIsOpen(false)}>
                                    Examples
                                </MobileNavLink>
                                <MobileNavLink href="/changelog" onClick={() => setIsOpen(false)}>
                                    Changelog
                                </MobileNavLink>
                                <MobileNavLink href="/about" onClick={() => setIsOpen(false)}>
                                    About
                                </MobileNavLink>
                                <MobileNavLink href="/contact" onClick={() => setIsOpen(false)}>
                                    Contact
                                </MobileNavLink>
                                <a
                                    href="https://github.com/hostspicaindia"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="block text-gray-700 hover:text-black hover:bg-gray-50 py-3 font-medium rounded-lg px-3 transition-colors"
                                    onClick={() => setIsOpen(false)}
                                >
                                    GitHub
                                </a>
                                <div className="pt-4">
                                    <Link
                                        href="/flutter/synclayer"
                                        className="block text-center px-5 py-3 bg-black text-white rounded-full hover:bg-gray-800 transition-colors font-medium"
                                        onClick={() => setIsOpen(false)}
                                    >
                                        Get Started →
                                    </Link>
                                </div>
                            </div>
                        </div>
                    )}
                </div>
            </div>
        </nav>
    );
}

function MobileNavLink({ href, children, onClick }: { href: string; children: React.ReactNode; onClick: () => void }) {
    return (
        <Link
            href={href}
            className="block text-gray-700 hover:text-black hover:bg-gray-50 py-3 font-medium rounded-lg px-3 transition-colors"
            onClick={onClick}
        >
            {children}
        </Link>
    );
}
