import Link from 'next/link';
import { ArrowRight } from 'lucide-react';
import { SiPython } from 'react-icons/si';

export default function PythonSDKs() {
    return (
        <div className="min-h-screen bg-white">
            <section className="px-6 pt-24 pb-32">
                <div className="max-w-4xl mx-auto text-center">
                    <div className="inline-flex items-center gap-2 px-3 py-1 bg-gray-100 text-gray-800 rounded-full text-xs font-medium mb-6">
                        <SiPython className="w-3 h-3 text-[#3776AB]" />
                        <span>Python Platform</span>
                    </div>

                    <h1 className="text-5xl md:text-6xl font-bold mb-6 leading-tight text-black">
                        Python Packages & Tools
                    </h1>

                    <p className="text-lg text-gray-700 mb-12 max-w-2xl mx-auto leading-relaxed">
                        Enterprise-grade Python packages for data science and backend development. Coming soon.
                    </p>

                    <div className="inline-flex items-center gap-2 px-6 py-3 bg-gray-100 text-gray-700 rounded-full text-sm font-medium">
                        <span className="w-2 h-2 bg-yellow-500 rounded-full animate-pulse"></span>
                        Coming Soon
                    </div>
                </div>
            </section>
        </div>
    );
}
