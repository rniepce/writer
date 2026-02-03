'use client';

import { useState } from 'react';
import ZenEditor from '@/components/Editor/ZenEditor';
import CouncilPanel from '@/components/Council/CouncilPanel';
import { polishText, PolishReport } from '@/lib/api';

export default function Home() {
  const [isPanelOpen, setIsPanelOpen] = useState(false);
  const [isPolishing, setIsPolishing] = useState(false);
  const [report, setReport] = useState<PolishReport | null>(null);
  const [error, setError] = useState<string | null>(null);

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
        chapter: '1',
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

  return (
    <main className="min-h-screen transition-colors duration-1000">
      <ZenEditor onPolish={handlePolish} isPolishing={isPolishing} />

      {/* Left Ghost Panel (Future: Project navigation) */}
      <div className="fixed inset-y-0 left-0 w-12 hover:w-64 transition-all duration-300 opacity-0 hover:opacity-100 z-50">
        {/* Left Panel Content */}
      </div>

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
