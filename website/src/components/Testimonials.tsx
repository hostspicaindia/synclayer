import { Quote } from 'lucide-react';

interface Testimonial {
    name: string;
    role: string;
    company: string;
    content: string;
    avatar?: string;
}

const testimonials: Testimonial[] = [
    {
        name: 'Alex Chen',
        role: 'Lead Developer',
        company: 'TechStart Inc',
        content: 'SyncLayer saved us months of development time. The offline-first architecture is exactly what we needed for our mobile app.',
    },
    {
        name: 'Sarah Johnson',
        role: 'CTO',
        company: 'DataFlow Solutions',
        content: 'The conflict resolution strategies are well thought out. We switched from Firebase to SyncLayer and never looked back.',
    },
    {
        name: 'Michael Rodriguez',
        role: 'Mobile Architect',
        company: 'CloudSync Apps',
        content: 'Clean API, excellent documentation, and production-ready from day one. This is how SDKs should be built.',
    },
];

export default function Testimonials() {
    return (
        <section className="px-6 py-20 bg-gray-50">
            <div className="max-w-6xl mx-auto">
                <div className="text-center mb-16">
                    <h2 className="text-4xl font-bold text-black mb-4">Loved by Developers</h2>
                    <p className="text-lg text-gray-700 max-w-2xl mx-auto">
                        See what developers are saying about SyncLayer
                    </p>
                </div>

                <div className="grid md:grid-cols-3 gap-6">
                    {testimonials.map((testimonial, i) => (
                        <TestimonialCard key={i} {...testimonial} />
                    ))}
                </div>
            </div>
        </section>
    );
}

function TestimonialCard({ name, role, company, content }: Testimonial) {
    return (
        <div className="bg-white border border-gray-200 rounded-2xl p-6 hover:border-black transition-colors">
            <Quote className="w-8 h-8 text-gray-300 mb-4" />
            <p className="text-gray-700 mb-6 leading-relaxed">{content}</p>
            <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center">
                    <span className="text-sm font-bold text-gray-700">
                        {name.split(' ').map(n => n[0]).join('')}
                    </span>
                </div>
                <div>
                    <div className="font-bold text-black">{name}</div>
                    <div className="text-sm text-gray-600">
                        {role} at {company}
                    </div>
                </div>
            </div>
        </div>
    );
}
