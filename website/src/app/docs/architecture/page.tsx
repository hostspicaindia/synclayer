import type { Metadata } from 'next';
import Link from 'next/link';
import { ArrowLeft, Database, Cpu, Cloud, GitBranch, Layers, Network } from 'lucide-react';

export const metadata: Metadata = {
    title: 'Architecture',
    description: 'Technical architecture and design patterns of SyncLayer',
};

export default function ArchitecturePage() {
    return (
        <div className="min-h-screen bg-white">
            <section className="px-6 py-12">
                <div className="max-w-4xl mx-auto">
                    <Link
                        href="/docs"
                        className="inline-flex items-center text-gray-700 hover:text-black mb-8 transition-colors"
                    >
                        <ArrowLeft className="w-4 h-4 mr-2" />
                        Back to Documentation
                    </Link>

                    <h1 className="text-5xl font-bold text-black mb-4">Architecture</h1>
                    <p className="text-xl text-gray-700 mb-12">
                        Understanding SyncLayer's technical architecture and design patterns
                    </p>

                    <div className="prose prose-lg max-w-none">
                        <Section title="Overview">
                            <p className="text-gray-700 mb-4">
                                SyncLayer is built on a three-layer architecture designed for offline-first applications:
                            </p>
                            <div className="grid md:grid-cols-3 gap-4 my-8">
                                <ArchCard
                                    icon={<Database className="w-8 h-8 text-blue-600" />}
                                    title="Local Storage"
                                    items={['Isar Database', 'Offline Queue', 'Version Tracking']}
                                />
                                <ArchCard
                                    icon={<Cpu className="w-8 h-8 text-purple-600" />}
                                    title="Sync Engine"
                                    items={['Event System', 'Conflict Resolution', 'Auto-Retry']}
                                />
                                <ArchCard
                                    icon={<Cloud className="w-8 h-8 text-green-600" />}
                                    title="Backend Layer"
                                    items={['REST Adapter', 'Firebase', 'Supabase']}
                                />
                            </div>
                        </Section>

                        <Section title="Local Storage Layer">
                            <p className="text-gray-700 mb-4">
                                The foundation of SyncLayer is built on <strong>Isar</strong>, a high-performance NoSQL database for Flutter.
                            </p>
                            <FeatureList
                                items={[
                                    'Zero-copy object access for maximum performance',
                                    'ACID compliance for data integrity',
                                    'Automatic indexing for fast queries',
                                    'Version tracking for conflict detection',
                                    'Offline queue for pending operations'
                                ]}
                            />
                            <CodeBlock
                                title="Data Model"
                                language="dart"
                                code={`@collection
class SyncEntity {
  Id id = Isar.autoIncrement;
  
  late String collectionName;
  late String entityId;
  late String data; // JSON string
  late int version;
  late DateTime lastModified;
  late bool isSynced;
}`}
                            />
                        </Section>

                        <Section title="Sync Engine">
                            <p className="text-gray-700 mb-4">
                                The sync engine is event-driven and handles all synchronization logic:
                            </p>

                            <SubSection title="Event System">
                                <p className="text-gray-700 mb-4">
                                    All operations emit events that you can listen to:
                                </p>
                                <CodeBlock
                                    language="dart"
                                    code={`SyncLayer.events.listen((event) {
  if (event is SyncStartedEvent) {
    // Sync started
  } else if (event is SyncCompletedEvent) {
    // Sync completed successfully
  } else if (event is SyncErrorEvent) {
    // Handle sync error
  } else if (event is ConflictDetectedEvent) {
    // Conflict detected
  }
});`}
                                />
                            </SubSection>

                            <SubSection title="Conflict Resolution">
                                <p className="text-gray-700 mb-4">
                                    Three built-in strategies for handling conflicts:
                                </p>
                                <div className="space-y-4 my-6">
                                    <StrategyCard
                                        name="Last Write Wins"
                                        description="The most recent modification (by timestamp) takes precedence"
                                        useCase="Best for: Simple apps, single-user scenarios"
                                    />
                                    <StrategyCard
                                        name="Server Wins"
                                        description="Server data always overrides local changes"
                                        useCase="Best for: Read-heavy apps, authoritative server"
                                    />
                                    <StrategyCard
                                        name="Client Wins"
                                        description="Local changes always override server data"
                                        useCase="Best for: Offline-first apps, user autonomy"
                                    />
                                </div>
                            </SubSection>

                            <SubSection title="Retry Logic">
                                <p className="text-gray-700 mb-4">
                                    Intelligent retry with exponential backoff:
                                </p>
                                <CodeBlock
                                    language="dart"
                                    code={`SyncConfig(
  maxRetries: 3,
  retryDelay: Duration(seconds: 2),
  // Retry delays: 2s, 4s, 8s
)`}
                                />
                            </SubSection>
                        </Section>

                        <Section title="Backend Adapters">
                            <p className="text-gray-700 mb-4">
                                SyncLayer uses the adapter pattern to support multiple backends:
                            </p>
                            <CodeBlock
                                language="dart"
                                code={`abstract class BackendAdapter {
  Future<Map<String, dynamic>> pull(
    String collection,
    DateTime? lastSync,
  );
  
  Future<void> push(
    String collection,
    List<Map<String, dynamic>> changes,
  );
  
  Future<void> delete(
    String collection,
    String id,
  );
}`}
                            />
                            <p className="text-gray-700 mt-4 mb-4">
                                Built-in adapters:
                            </p>
                            <div className="grid md:grid-cols-2 gap-4 my-6">
                                <AdapterCard
                                    name="REST Adapter"
                                    description="Standard HTTP REST API with configurable endpoints"
                                />
                                <AdapterCard
                                    name="Firebase Adapter"
                                    description="Cloud Firestore integration with real-time updates"
                                />
                                <AdapterCard
                                    name="Supabase Adapter"
                                    description="PostgreSQL-backed with real-time subscriptions"
                                />
                                <AdapterCard
                                    name="Appwrite Adapter"
                                    description="Self-hosted backend with built-in auth"
                                />
                            </div>
                        </Section>

                        <Section title="Data Flow">
                            <p className="text-gray-700 mb-4">
                                Understanding how data flows through SyncLayer:
                            </p>
                            <div className="bg-gray-50 border border-gray-200 rounded-xl p-6 my-6">
                                <FlowStep
                                    number={1}
                                    title="Local Operation"
                                    description="User performs CRUD operation (save, update, delete)"
                                />
                                <FlowStep
                                    number={2}
                                    title="Immediate Storage"
                                    description="Data saved to Isar database instantly"
                                />
                                <FlowStep
                                    number={3}
                                    title="Queue Addition"
                                    description="Operation added to sync queue if online"
                                />
                                <FlowStep
                                    number={4}
                                    title="Backend Sync"
                                    description="Queue processed and synced to backend"
                                />
                                <FlowStep
                                    number={5}
                                    title="Conflict Check"
                                    description="Version comparison and conflict resolution"
                                />
                                <FlowStep
                                    number={6}
                                    title="Update Local"
                                    description="Local database updated with resolved data"
                                    isLast
                                />
                            </div>
                        </Section>

                        <Section title="Performance Considerations">
                            <FeatureList
                                items={[
                                    'Batch operations for improved throughput',
                                    'Lazy loading for large datasets',
                                    'Indexed queries for fast lookups',
                                    'Debounced sync to reduce network calls',
                                    'Compression for network transfers'
                                ]}
                            />
                        </Section>

                        <div className="bg-blue-50 border border-blue-200 rounded-xl p-6 mt-12">
                            <h3 className="text-lg font-bold text-black mb-2">Learn More</h3>
                            <p className="text-gray-700 mb-4">
                                Dive deeper into specific topics:
                            </p>
                            <div className="flex flex-wrap gap-3">
                                <Link
                                    href="/docs/api"
                                    className="inline-flex items-center text-black font-semibold hover:underline"
                                >
                                    API Reference →
                                </Link>
                                <Link
                                    href="/docs/examples"
                                    className="inline-flex items-center text-black font-semibold hover:underline"
                                >
                                    Code Examples →
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

function SubSection({ title, children }: { title: string; children: React.ReactNode }) {
    return (
        <div className="mb-8">
            <h3 className="text-2xl font-bold text-black mb-4">{title}</h3>
            {children}
        </div>
    );
}

function ArchCard({ icon, title, items }: { icon: React.ReactNode; title: string; items: string[] }) {
    return (
        <div className="bg-white border border-gray-200 rounded-xl p-6">
            <div className="mb-4">{icon}</div>
            <h3 className="font-bold text-black mb-3">{title}</h3>
            <ul className="space-y-2">
                {items.map((item, i) => (
                    <li key={i} className="text-sm text-gray-700 flex items-start gap-2">
                        <span className="text-blue-600 mt-1">•</span>
                        {item}
                    </li>
                ))}
            </ul>
        </div>
    );
}

function FeatureList({ items }: { items: string[] }) {
    return (
        <ul className="space-y-3 my-6">
            {items.map((item, i) => (
                <li key={i} className="flex items-start gap-3 text-gray-700">
                    <span className="w-6 h-6 rounded-full bg-green-100 text-green-600 flex items-center justify-center flex-shrink-0 text-sm font-bold mt-0.5">
                        ✓
                    </span>
                    {item}
                </li>
            ))}
        </ul>
    );
}

function CodeBlock({ title, language, code }: { title?: string; language: string; code: string }) {
    return (
        <div className="bg-gray-900 rounded-xl overflow-hidden my-6">
            <div className="flex items-center justify-between px-4 py-2 bg-gray-800 border-b border-gray-700">
                {title && <span className="text-sm text-gray-200 font-semibold">{title}</span>}
                <span className="text-xs text-gray-300 font-mono ml-auto">{language}</span>
            </div>
            <pre className="p-4 overflow-x-auto">
                <code className="text-sm text-white font-mono whitespace-pre">{code}</code>
            </pre>
        </div>
    );
}

function StrategyCard({ name, description, useCase }: { name: string; description: string; useCase: string }) {
    return (
        <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
            <h4 className="font-bold text-black mb-2">{name}</h4>
            <p className="text-sm text-gray-700 mb-2">{description}</p>
            <p className="text-xs text-gray-600 italic">{useCase}</p>
        </div>
    );
}

function AdapterCard({ name, description }: { name: string; description: string }) {
    return (
        <div className="bg-white border border-gray-200 rounded-lg p-4">
            <h4 className="font-bold text-black mb-2">{name}</h4>
            <p className="text-sm text-gray-700">{description}</p>
        </div>
    );
}

function FlowStep({
    number,
    title,
    description,
    isLast = false
}: {
    number: number;
    title: string;
    description: string;
    isLast?: boolean;
}) {
    return (
        <div className={`flex gap-4 ${!isLast ? 'mb-6' : ''}`}>
            <div className="flex flex-col items-center">
                <div className="w-8 h-8 rounded-full bg-black text-white flex items-center justify-center font-bold text-sm flex-shrink-0">
                    {number}
                </div>
                {!isLast && <div className="w-0.5 h-full bg-gray-300 mt-2" />}
            </div>
            <div className="flex-1 pb-2">
                <h4 className="font-bold text-black mb-1">{title}</h4>
                <p className="text-sm text-gray-700">{description}</p>
            </div>
        </div>
    );
}
