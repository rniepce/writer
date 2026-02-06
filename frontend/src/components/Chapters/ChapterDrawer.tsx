'use client';

import { useState, useEffect } from 'react';
import { Plus, ChevronLeft, BookOpen } from 'lucide-react';
import ChapterCard from './ChapterCard';
import {
    ChapterCard as ChapterCardType,
    listChapters,
    createChapter,
    deleteChapter
} from '@/lib/chapters';

interface ChapterDrawerProps {
    activeChapterId: number | null;
    onSelectChapter: (chapterId: number) => void;
    onChaptersChange: () => void;
}

export default function ChapterDrawer({
    activeChapterId,
    onSelectChapter,
    onChaptersChange
}: ChapterDrawerProps) {
    const [isOpen, setIsOpen] = useState(false);
    const [chapters, setChapters] = useState<ChapterCardType[]>([]);
    const [isLoading, setIsLoading] = useState(false);

    // Load chapters
    const loadChapters = async () => {
        try {
            const data = await listChapters();
            setChapters(data);
        } catch (error) {
            console.error('Erro ao carregar capítulos:', error);
        }
    };

    useEffect(() => {
        loadChapters();
    }, []);

    // Reload when chapters change externally
    useEffect(() => {
        loadChapters();
    }, [onChaptersChange]);

    const handleCreateChapter = async () => {
        setIsLoading(true);
        try {
            const newChapter = await createChapter({
                title: `Capítulo ${chapters.length + 1}`,
            });
            await loadChapters();
            onSelectChapter(newChapter.id);
        } catch (error) {
            console.error('Erro ao criar capítulo:', error);
        } finally {
            setIsLoading(false);
        }
    };

    const handleDeleteChapter = async (id: number) => {
        if (!confirm('Remover este capítulo?')) return;

        try {
            await deleteChapter(id);
            await loadChapters();

            // If deleted active chapter, select first available
            if (id === activeChapterId && chapters.length > 1) {
                const remaining = chapters.filter(c => c.id !== id);
                if (remaining.length > 0) {
                    onSelectChapter(remaining[0].id);
                }
            }
        } catch (error) {
            console.error('Erro ao remover capítulo:', error);
        }
    };

    return (
        <>
            {/* Hover trigger zone - wider for easier activation */}
            <div
                className="fixed inset-y-0 left-0 w-8 z-40 cursor-pointer"
                onMouseEnter={() => setIsOpen(true)}
                onClick={() => setIsOpen(true)}
            >
                {/* Visual hint bar */}
                <div className={`
                    absolute left-0 top-1/2 -translate-y-1/2
                    w-1.5 h-32 bg-gradient-to-b from-amber-400 to-purple-500
                    rounded-r-full shadow-lg
                    transition-all duration-300
                    ${isOpen ? 'opacity-0' : 'opacity-70 hover:opacity-100 hover:w-2 hover:h-40'}
                `} />
            </div>

            {/* Drawer panel */}
            <div
                className={`
                    fixed inset-y-0 left-0 z-50
                    w-72 bg-stone-100/95 backdrop-blur-md
                    border-r border-stone-300
                    shadow-2xl
                    transform transition-transform duration-300 ease-out
                    ${isOpen ? 'translate-x-0' : '-translate-x-[calc(100%-1rem)]'}
                `}
                onMouseLeave={() => setIsOpen(false)}
            >
                {/* Collapsed indicator */}
                <div
                    className={`
                        absolute right-0 top-1/2 -translate-y-1/2 
                        w-4 h-24 bg-amber-600/20 rounded-r-full
                        flex items-center justify-center
                        transition-opacity duration-300
                        ${isOpen ? 'opacity-0' : 'opacity-100'}
                    `}
                >
                    <ChevronLeft size={12} className="text-amber-800" />
                </div>

                {/* Content */}
                <div className="h-full flex flex-col p-4">
                    {/* Header */}
                    <div className="flex items-center gap-2 mb-6 pb-4 border-b border-stone-300">
                        <BookOpen className="text-amber-700" size={20} />
                        <h2 className="font-serif text-lg font-semibold text-stone-800">
                            Capítulos
                        </h2>
                        <span className="ml-auto text-xs text-stone-500 bg-stone-200 px-2 py-0.5 rounded-full">
                            {chapters.length}
                        </span>
                    </div>

                    {/* Chapter list */}
                    <div className="flex-1 overflow-y-auto pr-1 -mr-1">
                        {chapters.length === 0 ? (
                            <div className="text-center py-8 text-stone-500">
                                <BookOpen size={32} className="mx-auto mb-2 opacity-50" />
                                <p className="text-sm">Nenhum capítulo ainda</p>
                                <p className="text-xs mt-1">Crie seu primeiro capítulo</p>
                            </div>
                        ) : (
                            chapters.map((chapter) => (
                                <ChapterCard
                                    key={chapter.id}
                                    chapter={chapter}
                                    isActive={chapter.id === activeChapterId}
                                    onClick={() => onSelectChapter(chapter.id)}
                                    onDelete={() => handleDeleteChapter(chapter.id)}
                                />
                            ))
                        )}
                    </div>

                    {/* New chapter button */}
                    <button
                        onClick={handleCreateChapter}
                        disabled={isLoading}
                        className="
                            mt-4 w-full py-3 
                            bg-amber-600 hover:bg-amber-700 
                            text-white font-medium
                            rounded-lg shadow-md
                            flex items-center justify-center gap-2
                            transition-colors duration-200
                            disabled:opacity-50 disabled:cursor-not-allowed
                        "
                    >
                        <Plus size={18} />
                        {isLoading ? 'Criando...' : 'Novo Capítulo'}
                    </button>
                </div>
            </div>
        </>
    );
}
