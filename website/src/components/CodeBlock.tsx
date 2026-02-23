'use client';

import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { vscDarkPlus } from 'react-syntax-highlighter/dist/esm/styles/prism';
import { Copy, Check } from 'lucide-react';
import { useState } from 'react';

interface CodeBlockProps {
    code: string;
    language: string;
    title?: string;
    showLineNumbers?: boolean;
}

export default function CodeBlock({
    code,
    language,
    title,
    showLineNumbers = false
}: CodeBlockProps) {
    const [copied, setCopied] = useState(false);

    const copyToClipboard = async () => {
        await navigator.clipboard.writeText(code);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
    };

    return (
        <div className="bg-gray-900 rounded-xl overflow-hidden my-6 border border-gray-800">
            <div className="flex items-center justify-between px-4 py-2 bg-gray-800 border-b border-gray-700">
                <div className="flex items-center gap-3">
                    {title && <span className="text-sm text-gray-300 font-semibold">{title}</span>}
                    <span className="text-xs text-gray-400 font-mono">{language}</span>
                </div>
                <button
                    onClick={copyToClipboard}
                    className="p-1.5 hover:bg-gray-700 rounded transition-colors"
                    aria-label="Copy code"
                >
                    {copied ? (
                        <Check className="w-4 h-4 text-green-400" />
                    ) : (
                        <Copy className="w-4 h-4 text-gray-400" />
                    )}
                </button>
            </div>
            <SyntaxHighlighter
                language={language}
                style={vscDarkPlus}
                showLineNumbers={showLineNumbers}
                customStyle={{
                    margin: 0,
                    padding: '1rem',
                    background: 'transparent',
                    fontSize: '0.875rem',
                }}
                codeTagProps={{
                    style: {
                        fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace',
                    }
                }}
            >
                {code}
            </SyntaxHighlighter>
        </div>
    );
}
