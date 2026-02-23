'use client';

import { useState, useEffect } from 'react';
import { Star, GitFork, Eye } from 'lucide-react';

interface GitHubStats {
    stars: number;
    forks: number;
    watchers: number;
    loading: boolean;
    error: boolean;
}

export default function GitHubStats({ repo = 'hostspicaindia/synclayer' }: { repo?: string }) {
    const [stats, setStats] = useState<GitHubStats>({
        stars: 0,
        forks: 0,
        watchers: 0,
        loading: true,
        error: false,
    });

    useEffect(() => {
        fetch(`https://api.github.com/repos/${repo}`)
            .then(res => res.json())
            .then(data => {
                setStats({
                    stars: data.stargazers_count || 0,
                    forks: data.forks_count || 0,
                    watchers: data.watchers_count || 0,
                    loading: false,
                    error: false,
                });
            })
            .catch(() => {
                setStats(prev => ({ ...prev, loading: false, error: true }));
            });
    }, [repo]);

    if (stats.loading) {
        return (
            <div className="flex gap-4">
                <StatSkeleton />
                <StatSkeleton />
                <StatSkeleton />
            </div>
        );
    }

    if (stats.error) {
        return null;
    }

    return (
        <div className="flex flex-wrap gap-4">
            <StatBadge
                icon={<Star className="w-4 h-4" />}
                value={stats.stars}
                label="Stars"
            />
            <StatBadge
                icon={<GitFork className="w-4 h-4" />}
                value={stats.forks}
                label="Forks"
            />
            <StatBadge
                icon={<Eye className="w-4 h-4" />}
                value={stats.watchers}
                label="Watchers"
            />
        </div>
    );
}

function StatBadge({ icon, value, label }: { icon: React.ReactNode; value: number; label: string }) {
    return (
        <div className="flex items-center gap-2 px-4 py-2 bg-gray-100 rounded-lg border border-gray-200">
            <div className="text-gray-700">{icon}</div>
            <div>
                <div className="text-lg font-bold text-black">{value.toLocaleString()}</div>
                <div className="text-xs text-gray-600">{label}</div>
            </div>
        </div>
    );
}

function StatSkeleton() {
    return (
        <div className="flex items-center gap-2 px-4 py-2 bg-gray-100 rounded-lg border border-gray-200 animate-pulse">
            <div className="w-4 h-4 bg-gray-300 rounded"></div>
            <div>
                <div className="w-12 h-5 bg-gray-300 rounded mb-1"></div>
                <div className="w-16 h-3 bg-gray-300 rounded"></div>
            </div>
        </div>
    );
}
