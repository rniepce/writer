'use client';

import { useState, useEffect, useCallback } from 'react';
import ZenEditor from '@/components/Editor/ZenEditor';
import CouncilPanel from '@/components/Council/CouncilPanel';
import ChapterDrawer from '@/components/Chapters/ChapterDrawer';
import ProjectSelector from '@/components/Projects/ProjectSelector';
import ReferenceDocsPanel from '@/components/References/ReferenceDocsPanel';
import { polishText, PolishReport } from '@/lib/api';
import { getChapter, updateChapter, createChapter, listChapters } from '@/lib/chapters';
import { listProjects, getProject } from '@/lib/projects';
import { getReferenceDoc } from '@/lib/references';
import { Settings } from 'lucide-react';

export default function Home() {
  const [isPanelOpen, setIsPanelOpen] = useState(false);
  const [isPolishing, setIsPolishing] = useState(false);
  const [report, setReport] = useState<PolishReport | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Project state
  const [activeProjectId, setActiveProjectId] = useState<number | null>(null);
  const [projectTitle, setProjectTitle] = useState<string>('');

  // Chapter state
  const [activeChapterId, setActiveChapterId] = useState<number | null>(null);
  const [chapterContent, setChapterContent] = useState<string>('');
  const [chapterTitle, setChapterTitle] = useState<string>('');
  const [isSaving, setIsSaving] = useState(false);
  const [lastSaved, setLastSaved] = useState<Date | null>(null);
  const [refreshKey, setRefreshKey] = useState(0);

  // Reference docs state
  const [isRefPanelOpen, setIsRefPanelOpen] = useState(false);
  const [narrativeMapContent, setNarrativeMapContent] = useState<string>('');
  const [writingStyleContent, setWritingStyleContent] = useState<string>('');

  // Backend readiness state
  const [backendReady, setBackendReady] = useState(false);

  // Wait for the backend to be ready, then load projects
  useEffect(() => {
    let cancelled = false;
    const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:8001';

    const waitForBackend = async () => {
      const MAX_RETRIES = 30; // 30 × 1s = 30s max wait
      for (let i = 0; i < MAX_RETRIES; i++) {
        if (cancelled) return;
        try {
          const res = await fetch(`${API_BASE}/health`, { signal: AbortSignal.timeout(2000) });
          if (res.ok) {
            setBackendReady(true);
            // Now load projects
            try {
              const projects = await listProjects();
              if (projects.length > 0) {
                setActiveProjectId(projects[0].id);
                setProjectTitle(projects[0].title);
              }
            } catch (err) {
              console.error('Erro ao carregar projetos:', err);
            }
            return;
          }
        } catch {
          // Backend not ready yet
        }
        await new Promise(r => setTimeout(r, 1000));
      }
      console.error('Backend não respondeu após 30s');
      setBackendReady(true); // Show UI anyway
    };

    waitForBackend();
    return () => { cancelled = true; };
  }, []);

  // Load first chapter when project changes
  useEffect(() => {
    const loadFirstChapter = async () => {
      if (!activeProjectId) return;

      try {
        const chapters = await listChapters(activeProjectId);
        if (chapters.length > 0) {
          setActiveChapterId(chapters[0].id);
        } else {
          // Create first chapter for this project
          const newChapter = await createChapter({
            title: 'Capítulo 1',
            project_id: activeProjectId
          });
          setActiveChapterId(newChapter.id);
          setRefreshKey(k => k + 1);
        }
      } catch (err) {
        console.error('Erro ao carregar capítulos:', err);
      }
    };

    loadFirstChapter();
  }, [activeProjectId]);

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

  // Load reference docs when project changes
  const loadReferenceDocs = useCallback(async () => {
    if (!activeProjectId) return;
    try {
      const [narrativeDoc, styleDoc] = await Promise.all([
        getReferenceDoc(activeProjectId, 'narrative_map'),
        getReferenceDoc(activeProjectId, 'writing_style'),
      ]);
      setNarrativeMapContent(narrativeDoc?.content || '');
      setWritingStyleContent(styleDoc?.content || '');
    } catch (err) {
      console.error('Erro ao carregar referências:', err);
    }
  }, [activeProjectId]);

  useEffect(() => {
    loadReferenceDocs();
  }, [loadReferenceDocs]);

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
        project_name: projectTitle || 'Projeto',
        style_ref: 'Metamodernismo',
        chapter: chapterTitle,
        scene: '1',
        emotional_state: 'Reflexivo',
        narrative_map: narrativeMapContent,
        writing_style: writingStyleContent,
      });
      setReport(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro desconhecido');
    } finally {
      setIsPolishing(false);
    }
  };

  // Handle project selection
  const handleSelectProject = async (projectId: number | null) => {
    if (projectId === null) {
      // All projects deleted — clear everything
      setActiveProjectId(null);
      setActiveChapterId(null);
      setChapterContent('');
      setChapterTitle('');
      setProjectTitle('');
      return;
    }
    if (projectId !== activeProjectId) {
      setActiveProjectId(projectId);
      setActiveChapterId(null);
      setChapterContent('');
      setChapterTitle('');
      // Fetch and update project title
      try {
        const project = await getProject(projectId);
        setProjectTitle(project.title);
      } catch (err) {
        console.error('Erro ao buscar projeto:', err);
      }
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
      {/* Project Selector (Top Center) */}
      <ProjectSelector
        activeProjectId={activeProjectId}
        onSelectProject={handleSelectProject}
      />

      {/* Reference Docs Button (Top Right, next to save status) */}
      <button
        onClick={() => setIsRefPanelOpen(true)}
        className="fixed top-4 left-4 z-30 p-2 rounded-full bg-white/80 backdrop-blur shadow-sm
                   hover:bg-amber-50 hover:shadow-md text-gray-500 hover:text-amber-700
                   transition-all duration-200"
        title="Documentos de referência"
      >
        <Settings size={18} />
      </button>

      {/* Chapter Drawer (Left Ghost Panel) */}
      <ChapterDrawer
        projectId={activeProjectId}
        activeChapterId={activeChapterId}
        onSelectChapter={handleSelectChapter}
        onChaptersChange={() => setRefreshKey(k => k + 1)}
        key={`${activeProjectId}-${refreshKey}`}
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

      {/* Reference Docs Panel */}
      <ReferenceDocsPanel
        isOpen={isRefPanelOpen}
        onClose={() => setIsRefPanelOpen(false)}
        projectId={activeProjectId}
        onDocsChange={loadReferenceDocs}
      />
    </main>
  );
}

