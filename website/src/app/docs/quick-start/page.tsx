import type { Metadata } from 'next';
import Link from 'next/link';
import { ArrowLeft, Terminal, Code2, CheckCircle2 } from 'lucide-react';

export const metadata: Metadata = {
    title: 'Quick Start Guide',
    description: 'Get started with SyncLayer in minutes',
};

export default function QuickStartPage() {
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

                    <h1 className="text-5xl font-bold text-black mb-4">Quick Start</h1>
                    <p className="text-xl text-gray-700 mb-12">
                        Get up and running with SyncLayer in less than 5 minutes
                    </p>

                    <div className="prose prose-lg max-w-none">
                        <Step number={1} title="Installation">
                            <p className="text-gray-700 mb-4">
                                Add SyncLayer to your Flutter project's <code className="text-sm bg-gray-100 px-2 py-1 rounded">pubspec.yaml</code>:
                            </p>
                            <CodeBlock
                                language="yaml"
                                code={`dependencies:
  synclayer: ^0.2.0-beta.5`}
                            />
                            <p className="text-gray-700 mt-4">Then run:</p>
                            <CodeBlock
                                language="bash"
                                code="flutter pub get"
                            />
                        </Step>

                        <Step number={2} title="Initialize SyncLayer">
                            <p className="text-gray-700 mb-4">
                                Initialize SyncLayer in your app's main function:
                            </p>
                            <CodeBlock
                                language="dart"
                                code={`import 'package:synclayer/synclayer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SyncLayer.init(
    SyncConfig(
      baseUrl: 'https://api.example.com',
      collections: ['todos', 'users'],
      conflictStrategy: ConflictStrategy.lastWriteWins,
    ),
  );
  
  runApp(MyApp());
}`}
                            />
                        </Step>

                        <Step number={3} title="Perform CRUD Operations">
                            <p className="text-gray-700 mb-4">
                                Start using SyncLayer to save, retrieve, update, and delete data:
                            </p>
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
                        </Step>

                        <Step number={4} title="Watch for Changes">
                            <p className="text-gray-700 mb-4">
                                Listen to real-time updates from your local database:
                            </p>
                            <CodeBlock
                                language="dart"
                                code={`SyncLayer
  .collection('todos')
  .watch()
  .listen((todos) {
    print('Todos updated: \${todos.length} items');
    // Update your UI
  });`}
                            />
                        </Step>

                        <Step number={5} title="Sync with Backend">
                            <p className="text-gray-700 mb-4">
                                Trigger manual sync or let automatic sync handle it:
                            </p>
                            <CodeBlock
                                language="dart"
                                code={`// Manual sync
await SyncLayer.syncNow();

// Listen to sync events
SyncLayer.events.listen((event) {
  if (event is SyncStartedEvent) {
    print('Sync started');
  } else if (event is SyncCompletedEvent) {
    print('Sync completed');
  }
});`}
                            />
                        </Step>

                        <div className="bg-green-50 border border-green-200 rounded-xl p-6 mt-12">
                            <div className="flex items-start gap-3">
                                <CheckCircle2 className="w-6 h-6 text-green-600 flex-shrink-0 mt-1" />
                                <div>
                                    <h3 className="text-lg font-bold text-black mb-2">You're all set!</h3>
                                    <p className="text-gray-700 mb-4">
                                        Your app now has offline-first capabilities with automatic synchronization.
                                    </p>
                                    <div className="flex flex-wrap gap-3">
                                        <Link
                                            href="/docs/architecture"
                                            className="inline-flex items-center text-black font-semibold hover:underline"
                                        >
                                            Learn about Architecture →
                                        </Link>
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
                                            View Examples →
                                        </Link>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div className="mt-12 pt-8 border-t border-gray-200">
                            <h2 className="text-2xl font-bold text-black mb-4">Next Steps</h2>
                            <div className="grid md:grid-cols-2 gap-4">
                                <NextStepCard
                                    title="Configure Backend Adapters"
                                    description="Learn how to connect to Firebase, Supabase, or custom backends"
                                    href="/docs/adapters"
                                />
                                <NextStepCard
                                    title="Handle Conflicts"
                                    description="Understand conflict resolution strategies"
                                    href="/docs/conflicts"
                                />
                                <NextStepCard
                                    title="Monitor Events"
                                    description="Track sync status and handle errors"
                                    href="/docs/events"
                                />
                                <NextStepCard
                                    title="Production Checklist"
                                    description="Best practices for deploying to production"
                                    href="/docs/production"
                                />
                            </div>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    );
}

function Step({ number, title, children }: { number: number; title: string; children: React.ReactNode }) {
    return (
        <div className="mb-12">
            <div className="flex items-center gap-4 mb-4">
                <div className="w-10 h-10 rounded-full bg-black text-white flex items-center justify-center font-bold flex-shrink-0">
                    {number}
                </div>
                <h2 className="text-3xl font-bold text-black">{title}</h2>
            </div>
            <div className="ml-14">
                {children}
            </div>
        </div>
    );
}

function CodeBlock({ language, code }: { language: string; code: string }) {
    return (
        <div className="bg-gray-900 rounded-xl overflow-hidden my-4">
            <div className="flex items-center justify-between px-4 py-2 bg-gray-800 border-b border-gray-700">
                <span className="text-xs text-gray-300 font-mono">{language}</span>
            </div>
            <pre className="p-4 overflow-x-auto">
                <code className="text-sm text-white font-mono">{code}</code>
            </pre>
        </div>
    );
}

function NextStepCard({ title, description, href }: { title: string; description: string; href: string }) {
    return (
        <Link
            href={href}
            className="block p-4 bg-gray-50 border border-gray-200 rounded-lg hover:border-black transition-colors"
        >
            <h3 className="font-bold text-black mb-1">{title}</h3>
            <p className="text-sm text-gray-700">{description}</p>
        </Link>
    );
}
