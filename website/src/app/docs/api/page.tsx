import type { Metadata } from 'next';
import Link from 'next/link';
import { ArrowLeft, Code2 } from 'lucide-react';

export const metadata: Metadata = {
    title: 'API Reference',
    description: 'Complete API reference for SyncLayer SDK',
};

export default function APIPage() {
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

                    <h1 className="text-5xl font-bold text-black mb-4">API Reference</h1>
                    <p className="text-xl text-gray-700 mb-12">
                        Complete API documentation for SyncLayer SDK
                    </p>

                    <div className="prose prose-lg max-w-none">
                        <Section title="SyncLayer">
                            <p className="text-gray-700 mb-4">
                                The main entry point for the SyncLayer SDK.
                            </p>

                            <APIMethod
                                name="init"
                                signature="static Future<void> init(SyncConfig config)"
                                description="Initialize SyncLayer with configuration"
                                params={[
                                    { name: 'config', type: 'SyncConfig', description: 'Configuration object' }
                                ]}
                                returns="Future<void>"
                                example={`await SyncLayer.init(
  SyncConfig(
    baseUrl: 'https://api.example.com',
    collections: ['todos', 'users'],
    conflictStrategy: ConflictStrategy.lastWriteWins,
  ),
);`}
                            />

                            <APIMethod
                                name="collection"
                                signature="static CollectionManager collection(String name)"
                                description="Get a collection manager for CRUD operations"
                                params={[
                                    { name: 'name', type: 'String', description: 'Collection name' }
                                ]}
                                returns="CollectionManager"
                                example={`final todos = SyncLayer.collection('todos');`}
                            />

                            <APIMethod
                                name="syncNow"
                                signature="static Future<void> syncNow()"
                                description="Trigger immediate synchronization"
                                params={[]}
                                returns="Future<void>"
                                example={`await SyncLayer.syncNow();`}
                            />

                            <APIMethod
                                name="events"
                                signature="static Stream<SyncEvent> get events"
                                description="Stream of sync events"
                                params={[]}
                                returns="Stream<SyncEvent>"
                                example={`SyncLayer.events.listen((event) {
  if (event is SyncStartedEvent) {
    print('Sync started');
  }
});`}
                            />

                            <APIMethod
                                name="dispose"
                                signature="static Future<void> dispose()"
                                description="Clean up resources and close connections"
                                params={[]}
                                returns="Future<void>"
                                example={`await SyncLayer.dispose();`}
                            />
                        </Section>

                        <Section title="SyncConfig">
                            <p className="text-gray-700 mb-4">
                                Configuration object for initializing SyncLayer.
                            </p>

                            <ConfigTable
                                properties={[
                                    { name: 'baseUrl', type: 'String?', required: false, description: 'Base URL for REST API (required if no custom adapter)' },
                                    { name: 'collections', type: 'List<String>', required: true, description: 'List of collection names to sync' },
                                    { name: 'conflictStrategy', type: 'ConflictStrategy', required: false, default: 'lastWriteWins', description: 'Strategy for conflict resolution' },
                                    { name: 'syncInterval', type: 'Duration', required: false, default: '30 seconds', description: 'Automatic sync interval' },
                                    { name: 'maxRetries', type: 'int', required: false, default: '3', description: 'Maximum retry attempts' },
                                    { name: 'retryDelay', type: 'Duration', required: false, default: '2 seconds', description: 'Delay between retries' },
                                    { name: 'customBackendAdapter', type: 'BackendAdapter?', required: false, description: 'Custom backend adapter' },
                                    { name: 'authToken', type: 'String?', required: false, description: 'Authentication token' },
                                ]}
                            />
                        </Section>

                        <Section title="CollectionManager">
                            <p className="text-gray-700 mb-4">
                                Manages CRUD operations for a specific collection.
                            </p>

                            <APIMethod
                                name="save"
                                signature="Future<String> save(Map<String, dynamic> data, {String? id})"
                                description="Save or update a document"
                                params={[
                                    { name: 'data', type: 'Map<String, dynamic>', description: 'Document data' },
                                    { name: 'id', type: 'String?', description: 'Optional document ID (for updates)' }
                                ]}
                                returns="Future<String> - Document ID"
                                example={`final id = await SyncLayer
  .collection('todos')
  .save({'text': 'Buy milk', 'done': false});`}
                            />

                            <APIMethod
                                name="get"
                                signature="Future<Map<String, dynamic>?> get(String id)"
                                description="Retrieve a document by ID"
                                params={[
                                    { name: 'id', type: 'String', description: 'Document ID' }
                                ]}
                                returns="Future<Map<String, dynamic>?>"
                                example={`final todo = await SyncLayer
  .collection('todos')
  .get(id);`}
                            />

                            <APIMethod
                                name="getAll"
                                signature="Future<List<Map<String, dynamic>>> getAll()"
                                description="Retrieve all documents in collection"
                                params={[]}
                                returns="Future<List<Map<String, dynamic>>>"
                                example={`final todos = await SyncLayer
  .collection('todos')
  .getAll();`}
                            />

                            <APIMethod
                                name="delete"
                                signature="Future<void> delete(String id)"
                                description="Delete a document by ID"
                                params={[
                                    { name: 'id', type: 'String', description: 'Document ID' }
                                ]}
                                returns="Future<void>"
                                example={`await SyncLayer
  .collection('todos')
  .delete(id);`}
                            />

                            <APIMethod
                                name="watch"
                                signature="Stream<List<Map<String, dynamic>>> watch()"
                                description="Watch for real-time changes"
                                params={[]}
                                returns="Stream<List<Map<String, dynamic>>>"
                                example={`SyncLayer
  .collection('todos')
  .watch()
  .listen((todos) {
    print('Updated: \${todos.length} items');
  });`}
                            />
                        </Section>

                        <Section title="ConflictStrategy">
                            <p className="text-gray-700 mb-4">
                                Enum for conflict resolution strategies.
                            </p>

                            <EnumTable
                                values={[
                                    { name: 'lastWriteWins', description: 'Most recent modification wins (by timestamp)' },
                                    { name: 'serverWins', description: 'Server data always takes precedence' },
                                    { name: 'clientWins', description: 'Local changes always take precedence' },
                                ]}
                            />
                        </Section>

                        <Section title="Events">
                            <p className="text-gray-700 mb-4">
                                Event types emitted by SyncLayer.
                            </p>

                            <EventTable
                                events={[
                                    { name: 'SyncStartedEvent', description: 'Sync process started', properties: ['timestamp'] },
                                    { name: 'SyncCompletedEvent', description: 'Sync completed successfully', properties: ['timestamp', 'itemsSynced'] },
                                    { name: 'SyncErrorEvent', description: 'Sync error occurred', properties: ['timestamp', 'error', 'stackTrace'] },
                                    { name: 'ConflictDetectedEvent', description: 'Conflict detected during sync', properties: ['timestamp', 'collection', 'entityId'] },
                                    { name: 'ConnectivityChangedEvent', description: 'Network connectivity changed', properties: ['timestamp', 'isOnline'] },
                                ]}
                            />
                        </Section>

                        <Section title="Backend Adapters">
                            <p className="text-gray-700 mb-4">
                                Built-in backend adapters for different services.
                            </p>

                            <SubSection title="FirebaseAdapter">
                                <CodeBlock
                                    language="dart"
                                    code={`import 'package:synclayer/adapters/firebase_adapter.dart';

await SyncLayer.init(
  SyncConfig(
    collections: ['todos'],
    customBackendAdapter: FirebaseAdapter(
      firestore: FirebaseFirestore.instance,
    ),
  ),
);`}
                                />
                            </SubSection>

                            <SubSection title="SupabaseAdapter">
                                <CodeBlock
                                    language="dart"
                                    code={`import 'package:synclayer/adapters/supabase_adapter.dart';

await SyncLayer.init(
  SyncConfig(
    collections: ['todos'],
    customBackendAdapter: SupabaseAdapter(
      client: Supabase.instance.client,
    ),
  ),
);`}
                                />
                            </SubSection>

                            <SubSection title="AppwriteAdapter">
                                <CodeBlock
                                    language="dart"
                                    code={`import 'package:synclayer/adapters/appwrite_adapter.dart';

await SyncLayer.init(
  SyncConfig(
    collections: ['todos'],
    customBackendAdapter: AppwriteAdapter(
      databases: databases,
      databaseId: 'your-database-id',
    ),
  ),
);`}
                                />
                            </SubSection>
                        </Section>

                        <div className="bg-blue-50 border border-blue-200 rounded-xl p-6 mt-12">
                            <h3 className="text-lg font-bold text-black mb-2">Need Help?</h3>
                            <p className="text-gray-700 mb-4">
                                Check out our examples and guides for more detailed usage.
                            </p>
                            <div className="flex flex-wrap gap-3">
                                <Link
                                    href="/docs/examples"
                                    className="inline-flex items-center text-black font-semibold hover:underline"
                                >
                                    View Examples →
                                </Link>
                                <Link
                                    href="/docs/quick-start"
                                    className="inline-flex items-center text-black font-semibold hover:underline"
                                >
                                    Quick Start →
                                </Link>
                                <a
                                    href="https://github.com/hostspicaindia/synclayer/issues"
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="inline-flex items-center text-black font-semibold hover:underline"
                                >
                                    Report Issue →
                                </a>
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
            <h2 className="text-3xl font-bold text-black mb-6 pb-2 border-b-2 border-gray-200">{title}</h2>
            {children}
        </div>
    );
}

function SubSection({ title, children }: { title: string; children: React.ReactNode }) {
    return (
        <div className="mb-6">
            <h3 className="text-xl font-bold text-black mb-3">{title}</h3>
            {children}
        </div>
    );
}

function APIMethod({
    name,
    signature,
    description,
    params,
    returns,
    example
}: {
    name: string;
    signature: string;
    description: string;
    params: Array<{ name: string; type: string; description: string }>;
    returns: string;
    example: string;
}) {
    return (
        <div className="mb-8 bg-gray-50 border border-gray-200 rounded-xl p-6">
            <h3 className="text-xl font-bold text-black mb-2">{name}</h3>
            <code className="text-sm bg-gray-900 text-white px-3 py-1 rounded font-mono block mb-3 overflow-x-auto">
                {signature}
            </code>
            <p className="text-gray-700 mb-4">{description}</p>

            {params.length > 0 && (
                <div className="mb-4">
                    <h4 className="font-semibold text-black mb-2">Parameters:</h4>
                    <ul className="space-y-2">
                        {params.map((param, i) => (
                            <li key={i} className="text-sm">
                                <code className="bg-gray-200 px-2 py-0.5 rounded text-gray-900">{param.name}</code>
                                <span className="text-gray-600"> ({param.type})</span>
                                <span className="text-gray-700"> - {param.description}</span>
                            </li>
                        ))}
                    </ul>
                </div>
            )}

            <div className="mb-4">
                <h4 className="font-semibold text-black mb-2">Returns:</h4>
                <code className="text-sm bg-gray-200 px-2 py-1 rounded text-gray-900">{returns}</code>
            </div>

            <div>
                <h4 className="font-semibold text-black mb-2">Example:</h4>
                <CodeBlock language="dart" code={example} />
            </div>
        </div>
    );
}

function ConfigTable({ properties }: {
    properties: Array<{
        name: string;
        type: string;
        required: boolean;
        default?: string;
        description: string;
    }>;
}) {
    return (
        <div className="overflow-x-auto my-6">
            <table className="w-full border border-gray-200 rounded-lg overflow-hidden">
                <thead className="bg-gray-100">
                    <tr>
                        <th className="text-left py-3 px-4 font-semibold text-black">Property</th>
                        <th className="text-left py-3 px-4 font-semibold text-black">Type</th>
                        <th className="text-left py-3 px-4 font-semibold text-black">Required</th>
                        <th className="text-left py-3 px-4 font-semibold text-black">Default</th>
                        <th className="text-left py-3 px-4 font-semibold text-black">Description</th>
                    </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                    {properties.map((prop, i) => (
                        <tr key={i} className="hover:bg-gray-50">
                            <td className="py-3 px-4">
                                <code className="text-sm bg-gray-200 px-2 py-1 rounded text-gray-900">{prop.name}</code>
                            </td>
                            <td className="py-3 px-4 text-sm text-gray-700">{prop.type}</td>
                            <td className="py-3 px-4 text-sm">
                                {prop.required ? (
                                    <span className="text-red-600 font-semibold">Yes</span>
                                ) : (
                                    <span className="text-gray-500">No</span>
                                )}
                            </td>
                            <td className="py-3 px-4 text-sm text-gray-700">{prop.default || '-'}</td>
                            <td className="py-3 px-4 text-sm text-gray-700">{prop.description}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
}

function EnumTable({ values }: { values: Array<{ name: string; description: string }> }) {
    return (
        <div className="overflow-x-auto my-6">
            <table className="w-full border border-gray-200 rounded-lg overflow-hidden">
                <thead className="bg-gray-100">
                    <tr>
                        <th className="text-left py-3 px-4 font-semibold text-black">Value</th>
                        <th className="text-left py-3 px-4 font-semibold text-black">Description</th>
                    </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                    {values.map((value, i) => (
                        <tr key={i} className="hover:bg-gray-50">
                            <td className="py-3 px-4">
                                <code className="text-sm bg-gray-200 px-2 py-1 rounded text-gray-900">{value.name}</code>
                            </td>
                            <td className="py-3 px-4 text-sm text-gray-700">{value.description}</td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
}

function EventTable({ events }: {
    events: Array<{ name: string; description: string; properties: string[] }>;
}) {
    return (
        <div className="space-y-4 my-6">
            {events.map((event, i) => (
                <div key={i} className="bg-gray-50 border border-gray-200 rounded-lg p-4">
                    <div className="flex items-start justify-between mb-2">
                        <code className="text-sm bg-gray-900 text-white px-3 py-1 rounded font-mono">
                            {event.name}
                        </code>
                    </div>
                    <p className="text-sm text-gray-700 mb-2">{event.description}</p>
                    <div className="text-xs text-gray-600">
                        Properties: {event.properties.join(', ')}
                    </div>
                </div>
            ))}
        </div>
    );
}

function CodeBlock({ language, code }: { language: string; code: string }) {
    return (
        <div className="bg-gray-900 rounded-lg overflow-hidden">
            <div className="flex items-center justify-between px-4 py-2 bg-gray-800 border-b border-gray-700">
                <span className="text-xs text-gray-300 font-mono">{language}</span>
            </div>
            <pre className="p-4 overflow-x-auto">
                <code className="text-sm text-white font-mono whitespace-pre">{code}</code>
            </pre>
        </div>
    );
}
