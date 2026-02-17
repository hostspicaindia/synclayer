'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function KeyboardShortcuts() {
    const router = useRouter();

    useEffect(() => {
        const handleKeyPress = (e: KeyboardEvent) => {
            // Only trigger if not in an input field
            if (
                e.target instanceof HTMLInputElement ||
                e.target instanceof HTMLTextAreaElement ||
                e.target instanceof HTMLSelectElement
            ) {
                return;
            }

            // Cmd/Ctrl + K for search (future feature)
            if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
                e.preventDefault();
                // TODO: Open search modal
                console.log('Search shortcut triggered');
            }

            // G + H for home
            if (e.key === 'g') {
                const nextKey = new Promise<string>((resolve) => {
                    const handler = (e: KeyboardEvent) => {
                        resolve(e.key);
                        window.removeEventListener('keydown', handler);
                    };
                    window.addEventListener('keydown', handler);
                    setTimeout(() => {
                        window.removeEventListener('keydown', handler);
                        resolve('');
                    }, 1000);
                });

                nextKey.then((key) => {
                    if (key === 'h') router.push('/');
                    if (key === 'd') router.push('/docs');
                    if (key === 'e') router.push('/examples');
                    if (key === 'c') router.push('/contact');
                });
            }

            // ? for keyboard shortcuts help
            if (e.key === '?' && e.shiftKey) {
                e.preventDefault();
                // TODO: Show keyboard shortcuts modal
                console.log('Keyboard shortcuts help');
            }
        };

        window.addEventListener('keydown', handleKeyPress);
        return () => window.removeEventListener('keydown', handleKeyPress);
    }, [router]);

    return null;
}
