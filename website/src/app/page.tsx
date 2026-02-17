'use client';

import Link from 'next/link';
import { ArrowRight, Code2, Zap, Shield, CheckCircle2, Copy, Check } from 'lucide-react';
import { SiFlutter, SiNpm, SiPython, SiGo, SiRust, SiDotnet } from 'react-icons/si';
import React from 'react';
import GitHubStats from '@/components/GitHubStats';
import Testimonials from '@/components/Testimonials';

function InstallCommand({ command }: { command: string }) {
  const [copied, setCopied] = React.useState(false);

  const copyToClipboard = async () => {
    await navigator.clipboard.writeText(command);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="relative group">
      <div className="bg-white border border-gray-200 rounded-lg p-4 pr-12 font-mono text-sm text-gray-900">
        {command}
      </div>
      <button
        onClick={copyToClipboard}
        className="absolute right-3 top-1/2 -translate-y-1/2 p-2 hover:bg-gray-100 rounded-md transition-colors"
        aria-label="Copy to clipboard"
      >
        {copied ? (
          <Check className="w-4 h-4 text-green-600" />
        ) : (
          <Copy className="w-4 h-4 text-gray-600" />
        )}
      </button>
    </div>
  );
}

export default function SDKHub() {
  return (
    <div className="min-h-screen bg-white">
      {/* Hero Section */}
      <section className="px-6 pt-20 pb-24">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-16">
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-800 rounded-full text-sm font-medium mb-8">
              <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
              Open Source SDK Platform
            </div>

            <h1 className="text-6xl md:text-7xl font-bold mb-8 leading-tight text-black">
              Build faster with<br />
              <span className="text-gray-400">production-ready</span> SDKs
            </h1>

            <p className="text-xl text-gray-700 mb-12 max-w-3xl mx-auto leading-relaxed">
              Enterprise-grade software development kits for Flutter, JavaScript, Python, and more.
              Save months of development time with battle-tested, well-documented libraries.
            </p>

            <div className="flex flex-col sm:flex-row gap-4 justify-center mb-16">
              <Link
                href="/flutter"
                className="inline-flex items-center justify-center px-8 py-4 bg-black text-white rounded-full hover:bg-gray-800 transition-colors text-base font-medium"
              >
                Explore SDKs <ArrowRight className="ml-2 w-5 h-5" />
              </Link>
              <a
                href="https://github.com/hostspicaindia"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center px-8 py-4 border-2 border-gray-300 text-black rounded-full hover:border-black transition-colors text-base font-medium"
              >
                View on GitHub
              </a>
            </div>

            {/* Trust Indicators */}
            <div className="flex flex-wrap items-center justify-center gap-8 text-sm text-gray-600">
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-green-600" />
                <span>Production Ready</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-green-600" />
                <span>Open Source</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-green-600" />
                <span>Well Documented</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-green-600" />
                <span>Active Support</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Why Choose Us */}
      <section className="px-6 py-20 bg-gray-50">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-black mb-4">Why developers choose our SDKs</h2>
            <p className="text-lg text-gray-700 max-w-2xl mx-auto">
              Built by developers, for developers. Every SDK is crafted with care and attention to detail.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            <FeatureCard
              icon={<Code2 className="w-8 h-8 text-black" />}
              title="Developer First"
              description="Clean APIs, intuitive design patterns, and comprehensive documentation. We obsess over developer experience."
            />
            <FeatureCard
              icon={<Zap className="w-8 h-8 text-black" />}
              title="Production Ready"
              description="Battle-tested in real applications. Comprehensive test coverage, performance optimized, and actively maintained."
            />
            <FeatureCard
              icon={<Shield className="w-8 h-8 text-black" />}
              title="Enterprise Grade"
              description="Built for scale with proper error handling, logging, and monitoring. Ready for mission-critical applications."
            />
          </div>
        </div>
      </section>

      {/* Platform Categories */}
      <section className="px-6 py-20">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-black mb-4">Choose your platform</h2>
            <p className="text-lg text-gray-700 max-w-2xl mx-auto">
              SDKs and libraries for every major development platform
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            <PlatformCard
              platform="Flutter"
              icon={<SiFlutter className="w-12 h-12 text-[#02569B]" />}
              description="Mobile & cross-platform development"
              sdkCount={1}
              href="/flutter"
              available
            />
            <PlatformCard
              platform="NPM"
              icon={<SiNpm className="w-12 h-12 text-[#CB3837]" />}
              description="JavaScript & TypeScript libraries"
              sdkCount={0}
              href="/npm"
              comingSoon
            />
            <PlatformCard
              platform="Python"
              icon={<SiPython className="w-12 h-12 text-[#3776AB]" />}
              description="Python packages & tools"
              sdkCount={0}
              href="/python"
              comingSoon
            />
            <PlatformCard
              platform="Go"
              icon={<SiGo className="w-12 h-12 text-[#00ADD8]" />}
              description="Go modules & packages"
              sdkCount={0}
              href="/go"
              comingSoon
            />
            <PlatformCard
              platform="Rust"
              icon={<SiRust className="w-12 h-12 text-[#000000]" />}
              description="Rust crates & libraries"
              sdkCount={0}
              href="/rust"
              comingSoon
            />
            <PlatformCard
              platform=".NET"
              icon={<SiDotnet className="w-12 h-12 text-[#512BD4]" />}
              description="C# & .NET libraries"
              sdkCount={0}
              href="/dotnet"
              comingSoon
            />
          </div>
        </div>
      </section>

      {/* Featured SDK */}
      <section className="px-6 py-20 bg-gray-50">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-black mb-4">Featured SDK</h2>
            <p className="text-lg text-gray-700 max-w-2xl mx-auto">
              Our flagship SDK, trusted by developers worldwide
            </p>
          </div>

          <div className="bg-white border border-gray-200 rounded-3xl p-10 shadow-sm">
            <div className="grid md:grid-cols-2 gap-12">
              <div>
                <div className="flex items-center gap-3 mb-2">
                  <SiFlutter className="w-10 h-10 text-[#02569B]" />
                  <div>
                    <h3 className="text-3xl font-bold text-black">SyncLayer</h3>
                  </div>
                </div>
                <p className="text-sm text-gray-600 font-mono mb-6">v0.2.0-beta.7</p>

                <p className="text-lg text-gray-700 mb-8 leading-relaxed">
                  Enterprise-grade local-first sync engine for Flutter. Build offline-first apps with automatic
                  synchronization, conflict resolution, and real-time updates. Now with logging, metrics, and 90% better performance!
                </p>

                <div className="space-y-3 mb-8">
                  <FeatureItem text="Offline-First Architecture" />
                  <FeatureItem text="Automatic Sync & Conflict Resolution" />
                  <FeatureItem text="Backend Agnostic (REST, Firebase, Supabase)" />
                  <FeatureItem text="Event-Driven System with Metrics" />
                  <FeatureItem text="Isar-Powered Storage with Indexes" />
                  <FeatureItem text="Production-Ready Logging Framework" />
                </div>

                <div className="flex flex-wrap gap-4">
                  <Link
                    href="/flutter/synclayer"
                    className="inline-flex items-center text-black font-semibold hover:gap-3 transition-all"
                  >
                    View Documentation <ArrowRight className="ml-2 w-5 h-5" />
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

                <div className="mt-6">
                  <GitHubStats />
                </div>
              </div>

              <div className="space-y-6">
                <div className="bg-gray-50 rounded-2xl p-6 border border-gray-200">
                  <h4 className="text-sm font-semibold text-gray-900 mb-4">Package Metrics</h4>
                  <div className="grid grid-cols-2 gap-6">
                    <MetricItem label="Package Size" value="632 KB" />
                    <MetricItem label="Tests Passing" value="6/6" />
                    <MetricItem label="Pub Score" value="160/160" />
                    <MetricItem label="Platforms" value="5" />
                  </div>
                </div>

                <div className="bg-gray-50 rounded-2xl p-6 border border-gray-200">
                  <h4 className="text-sm font-semibold text-gray-900 mb-4">Quick Install</h4>
                  <InstallCommand command="flutter pub add synclayer" />
                </div>

                <div className="flex flex-wrap items-center gap-2">
                  <span className="px-3 py-1.5 bg-green-50 text-green-700 rounded-full text-sm font-medium border border-green-200">
                    Production Ready
                  </span>
                  <span className="px-3 py-1.5 bg-blue-50 text-blue-700 rounded-full text-sm font-medium border border-blue-200">
                    Open Source
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="px-6 py-20">
        <div className="max-w-5xl mx-auto">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
            <StatCard value="1" label="SDK Available" sublabel="More coming soon" />
            <StatCard value="15" label="Fixes Applied" sublabel="Production ready" />
            <StatCard value="5" label="Platforms" sublabel="Cross-platform support" />
            <StatCard value="100%" label="Open Source" sublabel="MIT Licensed" />
          </div>
        </div>
      </section >

      {/* Testimonials */}
      <Testimonials />

      {/* CTA Section */}
      < section className="px-6 py-20 bg-gray-50" >
        <div className="max-w-4xl mx-auto text-center">
          <h2 className="text-5xl font-bold text-black mb-6">
            Start building today
          </h2>
          <p className="text-xl text-gray-700 mb-10 max-w-2xl mx-auto">
            Join developers who are building the next generation of applications with our SDKs
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/flutter"
              className="inline-flex items-center justify-center px-8 py-4 bg-black text-white rounded-full hover:bg-gray-800 transition-colors font-medium text-lg"
            >
              Browse SDKs <ArrowRight className="ml-2 w-5 h-5" />
            </Link>
            <a
              href="https://github.com/hostspicaindia"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-center px-8 py-4 border-2 border-gray-300 text-black rounded-full hover:border-black transition-colors font-medium text-lg"
            >
              View on GitHub
            </a>
          </div>
        </div>
      </section >
    </div >
  );
}

function FeatureCard({ icon, title, description }: { icon: React.ReactNode; title: string; description: string }) {
  return (
    <div className="bg-white border border-gray-200 rounded-2xl p-8 hover:border-gray-300 transition-colors">
      <div className="mb-4">{icon}</div>
      <h3 className="text-xl font-bold text-black mb-3">{title}</h3>
      <p className="text-gray-700 leading-relaxed">{description}</p>
    </div>
  );
}

function PlatformCard({
  platform,
  icon,
  description,
  sdkCount,
  href,
  available = false,
  comingSoon = false
}: {
  platform: string;
  icon: React.ReactNode;
  description: string;
  sdkCount: number;
  href: string;
  available?: boolean;
  comingSoon?: boolean;
}) {
  const content = (
    <div className={`group p-8 bg-white border rounded-2xl transition-all h-full ${available
      ? 'border-gray-300 hover:border-black cursor-pointer hover:shadow-sm'
      : 'border-gray-200 opacity-60'
      }`}>
      <div className="mb-6">{icon}</div>
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-2xl font-bold text-black">{platform}</h3>
        {comingSoon && (
          <span className="text-xs px-3 py-1 bg-gray-100 text-gray-600 rounded-full font-medium">Coming Soon</span>
        )}
        {available && (
          <span className="text-xs px-3 py-1 bg-green-50 text-green-700 rounded-full font-medium border border-green-200">
            {sdkCount} SDK{sdkCount !== 1 ? 's' : ''}
          </span>
        )}
      </div>
      <p className="text-gray-700 mb-4">{description}</p>
      {available && (
        <div className="flex items-center text-black font-medium group-hover:gap-2 transition-all">
          Explore SDKs <ArrowRight className="ml-1 w-4 h-4" />
        </div>
      )}
    </div>
  );

  return available ? <Link href={href}>{content}</Link> : <div>{content}</div>;
}

function FeatureItem({ text }: { text: string }) {
  return (
    <div className="flex items-center gap-3">
      <div className="w-5 h-5 rounded-full bg-green-50 border border-green-200 flex items-center justify-center flex-shrink-0">
        <CheckCircle2 className="w-3 h-3 text-green-600" />
      </div>
      <span className="text-gray-700">{text}</span>
    </div>
  );
}

function MetricItem({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <div className="text-2xl font-bold text-black mb-1">{value}</div>
      <div className="text-xs text-gray-600">{label}</div>
    </div>
  );
}

function StatCard({ value, label, sublabel }: { value: string; label: string; sublabel: string }) {
  return (
    <div className="text-center">
      <div className="text-4xl font-bold text-black mb-2">{value}</div>
      <div className="text-base font-medium text-gray-700 mb-1">{label}</div>
      <div className="text-sm text-gray-600">{sublabel}</div>
    </div>
  );
}
