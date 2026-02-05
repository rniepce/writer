'use client';

import { useState, useEffect, useCallback } from 'react';
import ZenEditor from '@/components/Editor/ZenEditor';
import CouncilPanel from '@/components/Council/CouncilPanel';
import ChapterDrawer from '@/components/Chapters/ChapterDrawer';
import { polishText, PolishReport } from '@/lib/api';
import { getChapter, updateChapter, createChapter, listChapters } from '@/lib/chapters';

export default function Home() {
  const [isPanelOpen, setIsPanelOpen] = useState(false);
  const [isPolishing, setIsPolishing] = useState(false);
  const [report, setReport] = useState<PolishReport | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Chapter state
  const [activeChapterId, setActiveChapterId] = useState<number | null>(null);
  const [chapterContent, setChapterContent] = useState<string>('');
  const [chapterTitle, setChapterTitle] = useState<string>('');
  const [isSaving, setIsSaving] = useState(false);
  const [lastSaved, setLastSaved] = useState<Date | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  // Initialize: load first chapter or create one
  useEffect(() => {
    const initChapters = async () => {
      try {
        const chapters = await listChapters();
        if (chapters.length > 0) {
          setActiveChapterId(chapters[0].id);
        } else {
          // Create first chapter automatically
          const newChapter = await createChapter({ title: 'Capítulo 1' });
          setActiveChapterId(newChapter.id);
        }
      } catch (err) {
        console.error('Erro ao inicializar capítulos:', err);
      }
    };

    initChapters();
  }, []);

  // Load chapter content when active chapter changes
  useEffect(() => {
    const loadChapter = async () => {
      if (!activeChapterId) return;

      try {
        const chapter = await getChapter(activeChapterId);
        setChapterContent(chapter.content);
        setChapterTitle(chapter.title);
        setLastSaved(new Date(chapter.updated_at));
      } catch (err) {
        console.error('Erro ao carregar capítulo:', err);
      }
    };

    loadChapter();
  }, [activeChapterId]);

  // Save chapter content
  const handleContentChange = useCallback(async (content: string) => {
    if (!activeChapterId) return;

    setIsSaving(true);
    try {
      await updateChapter(activeChapterId, { content });
      setLastSaved(new Date());
      setRefreshKey(k => k + 1); // Trigger drawer refresh
    } catch (err) {
      console.error('Erro ao salvar:', err);
    } finally {
      setIsSaving(false);
    }
  }, [activeChapterId]);

  // Polish text
  const handlePolish = async (text: string) => {
    setIsPolishing(true);
    setIsPanelOpen(true);
    setError(null);
    setReport(null);

    try {
      const result = await polishText({
        text,
        manuscript_context: 'Contexto geral do projeto literário.',
        project_name: 'Projeto',
        style_ref: 'Metamodernismo',
        chapter: chapterTitle,
        scene: '1',
        emotional_state: 'Reflexivo',
      });
      setReport(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro desconhecido');
    } finally {
      setIsPolishing(false);
    }
  };

  // Handle chapter selection
  const handleSelectChapter = (chapterId: number) => {
    if (chapterId !== activeChapterId) {
      setActiveChapterId(chapterId);
    }
  };

  return (
    <main className="min-h-screen transition-colors duration-1000">
      {/* Chapter Drawer (Left Ghost Panel) */}
      <ChapterDrawer
        activeChapterId={activeChapterId}
        onSelectChapter={handleSelectChapter}
        onChaptersChange={() => setRefreshKey(k => k + 1)}
        key={refreshKey}
      />

      {/* Main Editor */}
      <ZenEditor
        onPolish={handlePolish}
        isPolishing={isPolishing}
        initialContent={chapterContent}
        onContentChange={handleContentChange}
        isSaving={isSaving}
        lastSaved={lastSaved}
      />

      {/* Right Panel: Editorial Council */}
      <CouncilPanel
        isOpen={isPanelOpen}
        onClose={() => setIsPanelOpen(false)}
        isLoading={isPolishing}
        report={report}
        error={error}
      />
    </main>
  );
}
