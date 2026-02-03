'use client';

import { useEditor, EditorContent } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import Placeholder from '@tiptap/extension-placeholder';
import Typography from '@tiptap/extension-typography';
import { useEffect, useCallback } from 'react';
import { Sparkles } from 'lucide-react';

interface ZenEditorProps {
    onPolish: (text: string) => void;
    isPolishing: boolean;
}

export default function ZenEditor({ onPolish, isPolishing }: ZenEditorProps) {
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
        content: '<p></p>',
        immediatelyRender: false, // Fix SSR hydration mismatch
    });

    // Handle Polish Action
    const handlePolish = useCallback(() => {
        if (!editor || isPolishing) return;

        // Get selected text or full document
        const { from, to } = editor.state.selection;
        const hasSelection = from !== to;
        const text = hasSelection
            ? editor.state.doc.textBetween(from, to, ' ')
            : editor.getText();

        if (text.trim().length > 0) {
            onPolish(text);
        }
    }, [editor, onPolish, isPolishing]);

    // Keyboard shortcut: Cmd+Shift+P
    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            if ((e.metaKey || e.ctrlKey) && e.shiftKey && e.key === 'p') {
                e.preventDefault();
                handlePolish();
            }
        };

        document.addEventListener('keydown', handleKeyDown);
        return () => document.removeEventListener('keydown', handleKeyDown);
    }, [handlePolish]);

    if (!editor) {
        return null;
    }

    return (
        <div className="max-w-[800px] mx-auto pt-24 pb-48 px-8 transition-all duration-700">
            <EditorContent editor={editor} />

            {/* Polish Button - Fixed at bottom right of editor area */}
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
