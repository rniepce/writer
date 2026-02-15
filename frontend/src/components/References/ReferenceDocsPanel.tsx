'use client';

import { useState, useRef, useEffect } from 'react';
import { Map, Feather, Upload, Trash2, X, FileText, Check } from 'lucide-react';
import {
    ReferenceDocSummary,
    listReferenceDocs,
    upsertReferenceDoc,
    deleteReferenceDoc,
} from '@/lib/references';

interface ReferenceDocsPanelProps {
    isOpen: boolean;
    onClose: () => void;
    projectId: number | null;
    onDocsChange?: () => void;
}

interface DocSectionProps {
    title: string;
    description: string;
    icon: React.ReactNode;
    docType: 'narrative_map' | 'writing_style';
    projectId: number;
    doc: ReferenceDocSummary | null;
    onUpdated: () => void;
}

function DocSection({ title, description, icon, docType, projectId, doc, onUpdated }: DocSectionProps) {
    const fileInputRef = useRef<HTMLInputElement>(null);
    const [isUploading, setIsUploading] = useState(false);
    const [showSuccess, setShowSuccess] = useState(false);

    const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        setIsUploading(true);
        try {
            const text = await file.text();
            await upsertReferenceDoc(projectId, docType, text, file.name);
            setShowSuccess(true);
            setTimeout(() => setShowSuccess(false), 2000);
            onUpdated();
        } catch (err) {
            console.error('Erro ao enviar arquivo:', err);
        } finally {
            setIsUploading(false);
            if (fileInputRef.current) fileInputRef.current.value = '';
        }
    };

    const handleDelete = async () => {
        try {
            await deleteReferenceDoc(projectId, docType);
            onUpdated();
        } catch (err) {
            console.error('Erro ao remover:', err);
        }
    };

    return (
        <div className="border border-amber-200/60 rounded-lg p-4 bg-gradient-to-br from-amber-50/50 to-orange-50/30">
            {/* Header */}
            <div className="flex items-center gap-2 mb-2">
                <div className="p-1.5 bg-amber-100 rounded-md text-amber-700">
                    {icon}
                </div>
                <div>
                    <h3 className="font-semibold text-gray-800 text-sm">{title}</h3>
                    <p className="text-xs text-gray-500">{description}</p>
                </div>
            </div>

            {/* Current doc info */}
            {doc ? (
                <div className="mt-3 flex items-start gap-2">
                    <div className="flex-1 bg-white/70 rounded-md px-3 py-2 border border-amber-100">
                        <div className="flex items-center gap-1.5 text-xs text-amber-700 font-medium mb-1">
                            <FileText size={12} />
                            {doc.filename || 'Documento'}
                        </div>
                        <p className="text-xs text-gray-500 italic line-clamp-2">
                            {doc.preview || 'Sem conteúdo'}
                        </p>
                    </div>
                    <button
                        onClick={handleDelete}
                        className="p-1.5 hover:bg-red-50 text-red-400 hover:text-red-600 rounded transition-colors"
                        title="Remover documento"
                    >
                        <Trash2 size={14} />
                    </button>
                </div>
            ) : null}

            {/* Upload button */}
            <div className="mt-3">
                <input
                    ref={fileInputRef}
                    type="file"
                    accept=".txt,.md,.text"
                    onChange={handleFileSelect}
                    className="hidden"
                />
                <button
                    onClick={() => fileInputRef.current?.click()}
                    disabled={isUploading}
                    className={`
                        w-full flex items-center justify-center gap-2
                        px-3 py-2 rounded-md text-sm font-medium
                        transition-all duration-200
                        ${isUploading
                            ? 'bg-gray-100 text-gray-400 cursor-wait'
                            : showSuccess
                                ? 'bg-green-50 text-green-600 border border-green-200'
                                : doc
                                    ? 'bg-white text-amber-700 border border-amber-200 hover:bg-amber-50'
                                    : 'bg-amber-600 text-white hover:bg-amber-700 shadow-sm'
                        }
                    `}
                >
                    {isUploading ? (
                        <>
                            <Upload size={14} className="animate-pulse" />
                            Enviando...
                        </>
                    ) : showSuccess ? (
                        <>
                            <Check size={14} />
                            Salvo!
                        </>
                    ) : (
                        <>
                            <Upload size={14} />
                            {doc ? 'Substituir arquivo' : 'Enviar arquivo (.txt, .md)'}
                        </>
                    )}
                </button>
            </div>
        </div>
    );
}

export default function ReferenceDocsPanel({ isOpen, onClose, projectId, onDocsChange }: ReferenceDocsPanelProps) {
    const [docs, setDocs] = useState<ReferenceDocSummary[]>([]);

    const loadDocs = async () => {
        if (!projectId) return;
        try {
            const result = await listReferenceDocs(projectId);
            setDocs(result);
        } catch (err) {
            console.error('Erro ao carregar referências:', err);
        }
    };

    useEffect(() => {
        if (isOpen && projectId) {
            loadDocs();
        }
    }, [isOpen, projectId]);

    const handleUpdated = () => {
        loadDocs();
        onDocsChange?.();
    };

    const narrativeDoc = docs.find(d => d.doc_type === 'narrative_map') || null;
    const styleDoc = docs.find(d => d.doc_type === 'writing_style') || null;

    return (
        <>
            {/* Backdrop */}
            {isOpen && (
                <div
                    className="fixed inset-0 bg-black/20 backdrop-blur-sm z-40 transition-opacity"
                    onClick={onClose}
                />
            )}

            {/* Panel */}
            <div
                className={`
                    fixed top-0 right-0 h-full w-[380px] z-50
                    bg-gradient-to-b from-[#FAF8F0] to-[#F5F2E9]
                    shadow-2xl border-l border-amber-200/50
                    transition-transform duration-300 ease-in-out
                    ${isOpen ? 'translate-x-0' : 'translate-x-full'}
                `}
            >
                {/* Header */}
                <div className="flex items-center justify-between px-5 py-4 border-b border-amber-200/40">
                    <div>
                        <h2 className="font-serif font-bold text-gray-800">Documentos de Referência</h2>
                        <p className="text-xs text-gray-500 mt-0.5">Guias para o conselho editorial</p>
                    </div>
                    <button
                        onClick={onClose}
                        className="p-1.5 hover:bg-gray-100 rounded-md transition-colors"
                    >
                        <X size={18} className="text-gray-500" />
                    </button>
                </div>

                {/* Content */}
                <div className="p-5 space-y-5 overflow-y-auto h-[calc(100%-72px)]">
                    {!projectId ? (
                        <p className="text-sm text-gray-400 text-center mt-8">
                            Selecione um projeto primeiro.
                        </p>
                    ) : (
                        <>
                            <DocSection
                                title="Mapa Narrativo"
                                description="Estrutura da trama, arcos, timeline"
                                icon={<Map size={16} />}
                                docType="narrative_map"
                                projectId={projectId}
                                doc={narrativeDoc}
                                onUpdated={handleUpdated}
                            />

                            <DocSection
                                title="Estilo de Escrita"
                                description="Tom, voz, referências estilísticas"
                                icon={<Feather size={16} />}
                                docType="writing_style"
                                projectId={projectId}
                                doc={styleDoc}
                                onUpdated={handleUpdated}
                            />

                            {/* Info */}
                            <div className="mt-4 p-3 bg-blue-50/50 border border-blue-100 rounded-lg">
                                <p className="text-xs text-blue-600 leading-relaxed">
                                    💡 Estes documentos serão usados pelo Conselho Editorial ao analisar seu texto.
                                    O <strong>Mapa Narrativo</strong> guia a verificação de coerência, e o{' '}
                                    <strong>Estilo de Escrita</strong> orienta a análise de estilo e voz.
                                </p>
                            </div>
                        </>
                    )}
                </div>
            </div>
        </>
    );
}
