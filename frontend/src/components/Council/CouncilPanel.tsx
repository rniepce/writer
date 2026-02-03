'use client';

import { useState } from 'react';
import { PolishReport } from '@/lib/api';
import { X, Brain, Sparkles, Layers, Target, AlertTriangle, CheckCircle } from 'lucide-react';

interface CouncilPanelProps {
    isOpen: boolean;
    onClose: () => void;
    isLoading: boolean;
    report: PolishReport | null;
    error: string | null;
}

export default function CouncilPanel({ isOpen, onClose, isLoading, report, error }: CouncilPanelProps) {
    return (
        <div
            className={`fixed inset-y-0 right-0 z-50 transition-all duration-500 ease-out ${isOpen ? 'w-[420px] opacity-100' : 'w-0 opacity-0 pointer-events-none'
                }`}
        >
            <div className="h-full glass-panel overflow-hidden flex flex-col">
                {/* Header */}
                <div className="flex items-center justify-between p-4 border-b border-white/10">
                    <div className="flex items-center gap-2">
                        <Brain className="w-5 h-5 text-purple-600" />
                        <h2 className="font-sans font-semibold text-lg">Conselho Editorial</h2>
                    </div>
                    <button
                        onClick={onClose}
                        className="p-2 hover:bg-black/5 rounded-full transition-colors"
                    >
                        <X className="w-4 h-4" />
                    </button>
                </div>

                {/* Content */}
                <div className="flex-1 overflow-y-auto p-4 space-y-4">
                    {isLoading && (
                        <div className="flex flex-col items-center justify-center h-full space-y-4">
                            <div className="animate-spin rounded-full h-12 w-12 border-4 border-purple-500 border-t-transparent" />
                            <p className="text-sm text-gray-500 font-sans">
                                Consultando Claude, Gemini e GPT...
                            </p>
                        </div>
                    )}

                    {error && (
                        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
                            <div className="flex items-center gap-2 text-red-600 mb-2">
                                <AlertTriangle className="w-4 h-4" />
                                <span className="font-sans font-medium">Erro</span>
                            </div>
                            <p className="text-sm text-red-700">{error}</p>
                        </div>
                    )}

                    {report && !isLoading && (
                        <>
                            {/* Synthesis Section */}
                            <div className="space-y-3">
                                <SynthesisCard
                                    icon={<CheckCircle className="w-4 h-4 text-green-600" />}
                                    title="Consenso"
                                    content={report.consensus}
                                    color="green"
                                />
                                <SynthesisCard
                                    icon={<AlertTriangle className="w-4 h-4 text-amber-600" />}
                                    title="Divergência"
                                    content={report.divergence}
                                    color="amber"
                                />
                                <SynthesisCard
                                    icon={<Target className="w-4 h-4 text-purple-600" />}
                                    title="Veredito"
                                    content={report.verdict}
                                    color="purple"
                                />
                            </div>

                            {/* Individual Models */}
                            <div className="pt-4 border-t border-gray-200 space-y-3">
                                <h3 className="font-sans text-sm font-medium text-gray-500 uppercase tracking-wide">
                                    Análises Individuais
                                </h3>

                                <ModelCard
                                    icon={<Sparkles className="w-4 h-4" />}
                                    model={report.claude_style.model}
                                    focus="Estilo"
                                    analysis={report.claude_style.analysis}
                                    color="orange"
                                />
                                <ModelCard
                                    icon={<Brain className="w-4 h-4" />}
                                    model={report.gemini_coherence.model}
                                    focus="Coerência"
                                    analysis={report.gemini_coherence.analysis}
                                    color="blue"
                                />
                                <ModelCard
                                    icon={<Layers className="w-4 h-4" />}
                                    model={report.gpt_structure.model}
                                    focus="Estrutura"
                                    analysis={report.gpt_structure.analysis}
                                    color="green"
                                />
                            </div>
                        </>
                    )}
                </div>
            </div>
        </div>
    );
}

function SynthesisCard({
    icon,
    title,
    content,
    color,
}: {
    icon: React.ReactNode;
    title: string;
    content: string;
    color: 'green' | 'amber' | 'purple';
}) {
    const bgColors = {
        green: 'bg-green-50 border-green-200',
        amber: 'bg-amber-50 border-amber-200',
        purple: 'bg-purple-50 border-purple-200',
    };

    return (
        <div className={`rounded-lg border p-3 ${bgColors[color]}`}>
            <div className="flex items-center gap-2 mb-2">
                {icon}
                <span className="font-sans font-medium text-sm">{title}</span>
            </div>
            <p className="text-sm leading-relaxed">{content}</p>
        </div>
    );
}

function ModelCard({
    icon,
    model,
    focus,
    analysis,
    color,
}: {
    icon: React.ReactNode;
    model: string;
    focus: string;
    analysis: string;
    color: 'orange' | 'blue' | 'green';
}) {
    const [isExpanded, setIsExpanded] = useState(false);
    const previewLength = 200;

    const needsExpansion = analysis.length > previewLength;
    const displayText = isExpanded ? analysis : analysis.slice(0, previewLength);

    const borderColors = {
        orange: 'border-l-orange-400',
        blue: 'border-l-blue-400',
        green: 'border-l-green-400',
    };

    return (
        <div className={`bg-white/50 rounded-lg border border-gray-200 border-l-4 ${borderColors[color]} p-3`}>
            <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                    {icon}
                    <span className="font-sans font-medium text-sm">{model}</span>
                </div>
                <span className="text-xs bg-gray-100 px-2 py-1 rounded font-sans">{focus}</span>
            </div>
            <p className="text-sm leading-relaxed whitespace-pre-wrap">
                {displayText}
                {needsExpansion && !isExpanded && '...'}
            </p>
            {needsExpansion && (
                <button
                    onClick={() => setIsExpanded(!isExpanded)}
                    className="text-xs text-purple-600 hover:text-purple-800 mt-2 font-sans"
                >
                    {isExpanded ? 'Ver menos' : 'Ver mais'}
                </button>
            )}
        </div>
    );
}
