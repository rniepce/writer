'use client';

import { ChapterCard as ChapterCardType } from '@/lib/chapters';
import { FileText, Trash2 } from 'lucide-react';

interface ChapterCardProps {
    chapter: ChapterCardType;
    isActive: boolean;
    onClick: () => void;
    onDelete: () => void;
}

// Card colors palette (index cards feel)
const CARD_COLORS = [
    'from-amber-50 to-orange-100',      // Cream/Yellow
    'from-blue-50 to-sky-100',          // Light Blue
    'from-rose-50 to-pink-100',         // Pink
    'from-emerald-50 to-green-100',     // Light Green
    'from-violet-50 to-purple-100',     // Lavender
];

function getCardColor(index: number, customColor?: string | null): string {
    if (customColor) return customColor;
    return CARD_COLORS[index % CARD_COLORS.length];
}

function formatWordCount(count: number): string {
    if (count < 1000) return `${count} palavras`;
    return `${(count / 1000).toFixed(1)}k palavras`;
}

function timeAgo(dateStr: string): string {
    const date = new Date(dateStr);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);

    if (diffMins < 1) return 'agora';
    if (diffMins < 60) return `${diffMins}min atrás`;

    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `${diffHours}h atrás`;

    const diffDays = Math.floor(diffHours / 24);
    if (diffDays < 7) return `${diffDays}d atrás`;

    return date.toLocaleDateString('pt-BR', { day: '2-digit', month: 'short' });
}

export default function ChapterCard({ chapter, isActive, onClick, onDelete }: ChapterCardProps) {
    const colorClass = getCardColor(chapter.order, chapter.color);

    return (
        <div
            onClick={onClick}
            className={`
                relative group cursor-pointer
                p-4 rounded-sm mb-3
                bg-gradient-to-br ${colorClass}
                border-l-4 border-amber-700/40
                shadow-md hover:shadow-lg
                transition-all duration-200
                ${isActive
                    ? 'ring-2 ring-purple-500 scale-[1.02] -rotate-0'
                    : 'hover:scale-[1.01] -rotate-[0.5deg] hover:rotate-0'
                }
            `}
            style={{
                // Paper texture effect
                backgroundImage: `
                    linear-gradient(90deg, rgba(255,255,255,0.1) 0%, transparent 50%),
                    url("data:image/svg+xml,%3Csvg viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.8' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)' opacity='0.04'/%3E%3C/svg%3E")
                `,
            }}
        >
            {/* Delete button - appears on hover */}
            <button
                onClick={(e) => {
                    e.stopPropagation();
                    onDelete();
                }}
                className="
                    absolute top-2 right-2 p-1.5 rounded
                    opacity-0 group-hover:opacity-100
                    hover:bg-red-100 text-red-500
                    transition-opacity duration-200
                "
                title="Remover capítulo"
            >
                <Trash2 size={14} />
            </button>

            {/* Chapter number badge */}
            <div className="absolute -top-2 -left-1 w-6 h-6 rounded-full bg-amber-700/80 text-white text-xs flex items-center justify-center font-bold shadow">
                {chapter.order + 1}
            </div>

            {/* Title */}
            <h3 className="font-serif font-semibold text-gray-800 pr-6 mb-2 line-clamp-1">
                {chapter.title}
            </h3>

            {/* Preview */}
            <p className="text-sm text-gray-600 font-serif italic line-clamp-2 mb-3 min-h-[2.5rem]">
                {chapter.preview || 'Capítulo vazio...'}
            </p>

            {/* Footer */}
            <div className="flex items-center justify-between text-xs text-gray-500">
                <span className="flex items-center gap-1">
                    <FileText size={12} />
                    {formatWordCount(chapter.word_count)}
                </span>
                <span>{timeAgo(chapter.updated_at)}</span>
            </div>

            {/* Active indicator line */}
            {isActive && (
                <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-purple-500 rounded-full" />
            )}
        </div>
    );
}
