import type { Metadata } from 'next';
import Link from 'next/link';
import { ArrowRight, CheckCircle2, Database, Cpu, Cloud, GitBranch, RefreshCw, Network, Lock, Github as GithubIcon } from 'lucide-react';
import CodeBlock from '@/components/CodeBlock';

export const metadata: Metadata = {
  title: 'SyncLayer - Local-First Sync Engine for Flutter',
  description: 'Enterprise-grade local-first sync engine for Flutter with offline support, automatic conflict resolution, and real-time synchronization.',
};

export default function SyncLayerPage() {
  return (
    <div className="min-h-screen bg-white">
      {/* Hero Section */}
      <section className="px-6 pt-20 pb-24 bg-gradient-to-b from-gray-50 to-white">
        <div className="max-w-6xl mx-auto">
          {/* Status Badge */}
          <div className="flex items-center justify-center mb-6">
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-green-50 border border-green-200 text-green-700 rounded-full text-sm font-medium">
              <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
              <span className="font-mono">v0.2.0-beta.7</span>
              <span className="text-gray-400">•</span>
              <span>Production Ready • 15 Fixes</span>
            </div>
          </div>

          {/* Main Heading */}
          <h1 className="text-5xl md:text-6xl font-bold text-center mb-6 leading-tight text-black">
            Enterprise-Grade<br />
            Local-First Sync Engine
          </h1>

          {/* Subtitle */}
          <p className="text-xl text-gray-700 text-center mb-8 max-w-3xl mx-auto leading-relaxed">
            Production-ready synchronization infrastructure for Flutter. Built with Isar,
            powered by event-driven architecture, with logging, metrics, and 90% better performance.
          </p>

          {/* Metrics */}
          <div className="flex flex-wrap items-center justify-center gap-6 mb-12">
            <MetricBadge icon={<CheckCircle2 className="w-4 h-4 text-green-600" />} label="15 Critical Fixes" />
            <MetricBadge icon={<CheckCircle2 className="w-4 h-4 text-green-600" />} label="160/160 Pub Score" />
            <MetricBadge icon={<CheckCircle2 className="w-4 h-4 text-green-600" />} label="632 KB Package" />
            <MetricBadge icon={<CheckCircle2 className="w-4 h-4 text-green-600" />} label="90% Faster" />
          </div>

          {/* CTA Buttons */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center mb-16">
            <Link
              href="/docs/quick-start"
              className="inline-flex items-center justify-center px-8 py-4 bg-black text-white rounded-full hover:bg-gray-800 transition-colors font-semibold"
            >
              Quick Start
              <ArrowRight className="ml-2 w-5 h-5" />
            </Link>
            <Link
              href="/docs/architecture"
              className="inline-flex items-center justify-center px-8 py-4 border-2 border-gray-300 text-black rounded-full hover:border-black transition-colors font-semibold"
            >
              Architecture
            </Link>
            <a
              href="https://pub.dev/packages/synclayer"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-center px-8 py-4 border-2 border-gray-300 text-black rounded-full hover:border-black transition-colors font-semibold"
            >
              pub.dev
            </a>
          </div>

          {/* Architecture Diagram */}
          <div className="bg-white border border-gray-200 rounded-2xl p-8 shadow-sm">
            <div className="grid md:grid-cols-3 gap-6">
              <ArchitectureBlock
                title="Local Storage"
                icon={<Database className="w-6 h-6 text-blue-600" />}
                items={['Isar Database', 'Composite Indexes', 'SHA-256 Hashing']}
              />
              <ArchitectureBlock
                title="Sync Engine"
                icon={<Cpu className="w-6 h-6 text-purple-600" />}
                items={['Event-Driven', 'Logging & Metrics', 'Pagination Support']}
                highlight
              />
              <ArchitectureBlock
                title="Backend Adapters"
                icon={<Cloud className="w-6 h-6 text-green-600" />}
                items={['REST API', 'Firebase', 'Supabase']}
              />
            </div>
          </div>
        </div>
      </section>

      {/* Code Example Section */}
      <section className="px-6 py-20">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-4xl font-bold text-black mb-4">Developer Experience First</h2>
            <p className="text-gray-700 text-lg">Clean API. Zero boilerplate. Production ready.</p>
          </div>

          <div className="grid md:grid-cols-2 gap-6">
            <div>
              <h3 className="text-lg font-bold text-black mb-3">Installation</h3>
              <CodeBlock
                language="yaml"
                code={`dependencies:
  synclayer: ^0.2.0-beta.7

# Run
flutter pub get`}
              />
            </div>

            <div>
              <h3 className="text-lg font-bold text-black mb-3">Initialization</h3>
              <CodeBlock
                language="dart"
                code={`await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos', 'users'],
    conflictStrategy: ConflictStrategy.lastWriteWins,
  ),
);`}
              />
            </div>

            <div>
              <h3 className="text-lg font-bold text-black mb-3">CRUD Operations</h3>
              <CodeBlock
                language="dart"
                code={`// Create
final id = await SyncLayer
  .collection('todos')
  .save({'text': 'Buy milk', 'done': false});

// Read
final todo = await SyncLayer
  .collection('todos')
  .get(id);

// Update
await SyncLayer
  .collection('todos')
  .save({'done': true}, id: id);

// Delete
await SyncLayer
  .collection('todos')
  .delete(id);`}
              />
            </div>

            <div>
              <h3 className="text-lg font-bold text-black mb-3">Logging & Metrics</h3>
              <CodeBlock
                language="dart"
                code={`// Configure logging
SyncLayer.configureLogger(
  enabled: true,
  minLevel: LogLevel.warning,
);

// Get metrics
final metrics = SyncLayer.getMetrics();
print('Success rate: \${metrics.successRate}');`}
              />
            </div>
          </div>
        </div>
      </section>

      {/* Technical Features */}
      <section className="px-6 py-20 bg-gray-50">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-black mb-4">Built for Scale</h2>
            <p className="text-xl text-gray-700">Enterprise-grade features out of the box</p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            <TechFeature
              icon={<Database className="w-8 h-8 text-blue-600" />}
              title="Isar-Powered Storage"
              description="Lightning-fast local database with composite indexes and SHA-256 hashing for data integrity"
              metrics={['80% faster', 'Indexed queries', 'SHA-256 hash']}
            />
            <TechFeature
              icon={<Cpu className="w-8 h-8 text-purple-600" />}
              title="Logging & Metrics"
              description="Production-ready logging framework with configurable levels and comprehensive metrics tracking"
              metrics={['4 log levels', 'Success rates', 'Performance data']}
            />
            <TechFeature
              icon={<GitBranch className="w-8 h-8 text-orange-600" />}
              title="Conflict Resolution"
              description="Configurable strategies: last-write-wins, server-wins, client-wins with version tracking"
              metrics={['3 strategies', 'Version control', 'Hash-based']}
            />
            <TechFeature
              icon={<RefreshCw className="w-8 h-8 text-green-600" />}
              title="Intelligent Retry"
              description="Exponential backoff with configurable max retries and automatic queue management"
              metrics={['Auto-retry', 'Queue system', 'Failure handling']}
            />
            <TechFeature
              icon={<Network className="w-8 h-8 text-indigo-600" />}
              title="Connectivity Aware"
              description="Automatic network detection with seamless offline-to-online transitions"
              metrics={['Auto-detect', 'Seamless sync', 'Queue replay']}
            />
            <TechFeature
              icon={<Lock className="w-8 h-8 text-red-600" />}
              title="Backend Agnostic"
              description="Adapter pattern for any backend: REST, Firebase, Supabase, Appwrite, or custom"
              metrics={['4 adapters', 'Custom support', 'Type-safe']}
            />
          </div>
        </div>
      </section>

      {/* Performance Metrics */}
      <section className="px-6 py-20">
        <div className="max-w-6xl mx-auto">
          <div className="bg-gradient-to-r from-blue-50 to-purple-50 border border-blue-200 rounded-2xl p-12">
            <h2 className="text-3xl font-bold text-center text-black mb-12">Performance Improvements (v0.2.0-beta.7)</h2>
            <div className="grid md:grid-cols-4 gap-8">
              <PerformanceMetric
                value="90%"
                label="Less Memory"
                description="With pagination"
              />
              <PerformanceMetric
                value="80%"
                label="Faster Queries"
                description="With indexes"
              />
              <PerformanceMetric
                value="70%"
                label="Faster Bulk Ops"
                description="Batch operations"
              />
              <PerformanceMetric
                value="30s"
                label="Operation Timeout"
                description="Prevents hangs"
              />
            </div>
          </div>
        </div>
      </section>

      {/* Technical Comparison */}
      <section className="px-6 py-20 bg-gray-50">
        <div className="max-w-6xl mx-auto">
          <h2 className="text-3xl font-bold text-center text-black mb-12">Technical Comparison</h2>
          <div className="bg-white border border-gray-200 rounded-2xl overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-100">
                  <tr>
                    <th className="text-left py-4 px-6 font-semibold text-black">Feature</th>
                    <th className="text-center py-4 px-6 font-semibold text-blue-600">SyncLayer</th>
                    <th className="text-center py-4 px-6 font-semibold text-gray-600">Firebase</th>
                    <th className="text-center py-4 px-6 font-semibold text-gray-600">Supabase</th>
                    <th className="text-center py-4 px-6 font-semibold text-gray-600">Drift</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  <ComparisonRow feature="Offline-First" synclayer firebase supabase={false} drift />
                  <ComparisonRow feature="Auto-Sync" synclayer firebase supabase={false} drift={false} />
                  <ComparisonRow feature="Backend Agnostic" synclayer firebase={false} supabase={false} drift />
                  <ComparisonRow feature="Conflict Resolution" synclayer firebase supabase={false} drift={false} />
                  <ComparisonRow feature="Event System" synclayer firebase supabase drift={false} />
                  <ComparisonRow feature="Type-Safe" synclayer firebase supabase drift />
                  <ComparisonRow feature="Package Size" synclayer="632 KB" firebase="~2 MB" supabase="~1.5 MB" drift="~500 KB" />
                  <ComparisonRow feature="Free Tier" synclayer firebase="Limited" supabase="Limited" drift />
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </section>

      {/* Final CTA */}
      <section className="px-6 py-20">
        <div className="max-w-4xl mx-auto">
          <div className="bg-gradient-to-r from-blue-50 to-purple-50 border border-blue-200 rounded-2xl p-12 text-center">
            <h2 className="text-4xl font-bold text-black mb-4">Ready for Production</h2>
            <p className="text-xl text-gray-700 mb-8">
              Join developers building the next generation of offline-first applications
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link
                href="/docs/quick-start"
                className="inline-flex items-center justify-center px-8 py-4 bg-black text-white rounded-full hover:bg-gray-800 transition-colors font-semibold"
              >
                Start Building <ArrowRight className="ml-2 w-5 h-5" />
              </Link>
              <a
                href="https://github.com/hostspicaindia/synclayer"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 border-2 border-gray-300 text-black rounded-full hover:border-black transition-colors font-semibold"
              >
                <GithubIcon className="w-5 h-5" />
                View on GitHub
              </a>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}

function MetricBadge({ icon, label }: { icon: React.ReactNode; label: string }) {
  return (
    <div className="flex items-center gap-2 text-sm">
      {icon}
      <span className="text-gray-700 font-medium">{label}</span>
    </div>
  );
}

function ArchitectureBlock({
  title,
  icon,
  items,
  highlight = false
}: {
  title: string;
  icon: React.ReactNode;
  items: string[];
  highlight?: boolean;
}) {
  return (
    <div className={`p-6 rounded-xl border ${highlight ? 'border-blue-300 bg-blue-50' : 'border-gray-200 bg-gray-50'}`}>
      <div className="flex items-center gap-3 mb-4">
        {icon}
        <h3 className="text-lg font-semibold text-black">{title}</h3>
      </div>
      <ul className="space-y-2">
        {items.map((item, i) => (
          <li key={i} className="text-sm text-gray-700 flex items-center gap-2">
            <div className="w-1.5 h-1.5 rounded-full bg-blue-600" />
            {item}
          </li>
        ))}
      </ul>
    </div>
  );
}

function TechFeature({
  icon,
  title,
  description,
  metrics
}: {
  icon: React.ReactNode;
  title: string;
  description: string;
  metrics: string[];
}) {
  return (
    <div className="group p-6 bg-white border border-gray-200 rounded-xl hover:border-black transition-all">
      <div className="mb-4 group-hover:scale-110 transition-transform">
        {icon}
      </div>
      <h3 className="text-xl font-semibold text-black mb-2">{title}</h3>
      <p className="text-gray-700 mb-4 text-sm leading-relaxed">{description}</p>
      <div className="flex flex-wrap gap-2">
        {metrics.map((metric, i) => (
          <span key={i} className="text-xs px-2 py-1 bg-blue-50 text-blue-700 rounded border border-blue-200">
            {metric}
          </span>
        ))}
      </div>
    </div>
  );
}

function PerformanceMetric({ value, label, description }: { value: string; label: string; description: string }) {
  return (
    <div className="text-center">
      <div className="text-4xl font-bold text-blue-600 mb-2">{value}</div>
      <div className="text-lg font-semibold text-black mb-1">{label}</div>
      <div className="text-sm text-gray-600">{description}</div>
    </div>
  );
}

function ComparisonRow({
  feature,
  synclayer = true,
  firebase = true,
  supabase = true,
  drift = true
}: {
  feature: string;
  synclayer?: boolean | string;
  firebase?: boolean | string;
  supabase?: boolean | string;
  drift?: boolean | string;
}) {
  const renderCell = (value: boolean | string) => {
    if (typeof value === 'string') {
      return <span className="text-gray-700 text-sm">{value}</span>;
    }
    return value ? (
      <span className="text-green-600 text-xl font-bold">✓</span>
    ) : (
      <span className="text-gray-300 text-xl">✗</span>
    );
  };

  return (
    <tr className="hover:bg-gray-50 transition-colors">
      <td className="py-4 px-6 text-black font-medium">{feature}</td>
      <td className="text-center py-4 px-6">{renderCell(synclayer)}</td>
      <td className="text-center py-4 px-6">{renderCell(firebase)}</td>
      <td className="text-center py-4 px-6">{renderCell(supabase)}</td>
      <td className="text-center py-4 px-6">{renderCell(drift)}</td>
    </tr>
  );
}
