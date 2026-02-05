'use client';

import { useEditor, EditorContent } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import Placeholder from '@tiptap/extension-placeholder';
import Typography from '@tiptap/extension-typography';
import { useEffect, useCallback, useRef } from 'react';
import { Sparkles, Save, Check } from 'lucide-react';

interface ZenEditorProps {
    onPolish: (text: string) => void;
    isPolishing: boolean;
    initialContent?: string;
    onContentChange?: (content: string) => void;
    isSaving?: boolean;
    lastSaved?: Date | null;
}

export default function ZenEditor({
    onPolish,
    isPolishing,
    initialContent = '',
    onContentChange,
    isSaving = false,
    lastSaved = null,
}: ZenEditorProps) {
    const debounceRef = useRef<NodeJS.Timeout | null>(null);

    const editor = useEditor({
        extensions: [
            StarterKit,
            Typography,
            Placeholder.configure({
                placeholder: 'Comece a escrever...',
            }),
        ],
        editorProps: {
            attributes: {
                class: 'prose prose-lg prose-p:my-4 prose-p:leading-loose max-w-none focus:outline-none min-h-[calc(100vh-200px)]',
            },
        },
        content: initialContent || '<p></p>',
        immediatelyRender: false,
        onUpdate: ({ editor }) => {
            // Debounced auto-save
            if (debounceRef.current) {
                clearTimeout(debounceRef.current);
            }

            debounceRef.current = setTimeout(() => {
                const html = editor.getHTML();
                onContentChange?.(html);
            }, 2000); // 2 second debounce
        },
    });

    // Update content when initialContent changes (chapter switch)
    useEffect(() => {
        if (editor && initialContent !== undefined) {
            // Only update if content is actually different
            const currentContent = editor.getHTML();
            if (currentContent !== initialContent) {
                editor.commands.setContent(initialContent || '<p></p>');
            }
        }
    }, [editor, initialContent]);

    // Handle Polish Action
    const handlePolish = useCallback(() => {
        if (!editor || isPolishing) return;

        const { from, to } = editor.state.selection;
        const hasSelection = from !== to;
        const text = hasSelection
            ? editor.state.doc.textBetween(from, to, ' ')
            : editor.getText();

        if (text.trim().length > 0) {
            onPolish(text);
        }
    }, [editor, onPolish, isPolishing]);

    // Manual save (Cmd+S)
    const handleManualSave = useCallback(() => {
        if (!editor) return;

        // Clear debounce and save immediately
        if (debounceRef.current) {
            clearTimeout(debounceRef.current);
        }

        const html = editor.getHTML();
        onContentChange?.(html);
    }, [editor, onContentChange]);

    // Keyboard shortcuts
    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            // Cmd+Shift+P for Polish
            if ((e.metaKey || e.ctrlKey) && e.shiftKey && e.key === 'p') {
                e.preventDefault();
                handlePolish();
            }
            // Cmd+S for Save
            if ((e.metaKey || e.ctrlKey) && e.key === 's') {
                e.preventDefault();
                handleManualSave();
            }
        };

        document.addEventListener('keydown', handleKeyDown);
        return () => document.removeEventListener('keydown', handleKeyDown);
    }, [handlePolish, handleManualSave]);

    // Cleanup debounce on unmount
    useEffect(() => {
        return () => {
            if (debounceRef.current) {
                clearTimeout(debounceRef.current);
            }
        };
    }, []);

    if (!editor) {
        return null;
    }

    const formatLastSaved = (date: Date | null) => {
        if (!date) return '';
        const now = new Date();
        const diffMs = now.getTime() - date.getTime();
        const diffSecs = Math.floor(diffMs / 1000);

        if (diffSecs < 5) return 'Salvo agora';
        if (diffSecs < 60) return `Salvo há ${diffSecs}s`;
        return `Salvo às ${date.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })}`;
    };

    return (
        <div className="max-w-[800px] mx-auto pt-24 pb-48 px-8 transition-all duration-700">
            <EditorContent editor={editor} />

            {/* Save status indicator */}
            <div className="fixed top-4 right-4 z-30 flex items-center gap-2">
                {isSaving ? (
                    <span className="flex items-center gap-1.5 text-sm text-gray-500 bg-white/80 backdrop-blur px-3 py-1.5 rounded-full shadow-sm">
                        <Save size={14} className="animate-pulse" />
                        Salvando...
                    </span>
                ) : lastSaved ? (
                    <span className="flex items-center gap-1.5 text-sm text-green-600 bg-white/80 backdrop-blur px-3 py-1.5 rounded-full shadow-sm">
                        <Check size={14} />
                        {formatLastSaved(lastSaved)}
                    </span>
                ) : null}
            </div>

            {/* Polish Button */}
            <button
                onClick={handlePolish}
                disabled={isPolishing}
                className={`fixed bottom-8 right-8 z-40 flex items-center gap-2 px-4 py-2 rounded-full shadow-lg transition-all duration-300 ${isPolishing
                    ? 'bg-purple-300 cursor-not-allowed'
                    : 'bg-purple-600 hover:bg-purple-700 hover:scale-105'
                    } text-white font-sans text-sm`}
                title="Polir texto (⌘⇧P)"
            >
                <Sparkles className={`w-4 h-4 ${isPolishing ? 'animate-pulse' : ''}`} />
                {isPolishing ? 'Consultando...' : 'Polir'}
            </button>
        </div>
    );
}
