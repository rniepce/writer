'use client';

import { useEditor, EditorContent } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import Placeholder from '@tiptap/extension-placeholder';
import Typography from '@tiptap/extension-typography';
import { useEffect } from 'react';

export default function ZenEditor() {
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
    });

    // Typewriter Mode Effect (Basic Implementation)
    useEffect(() => {
        if (!editor) return;

        // Future: Add logic to scroll window to keep cursor centered
    }, [editor]);

    if (!editor) {
        return null;
    }

    return (
        <div className="max-w-[800px] mx-auto pt-24 pb-48 px-8 transition-all duration-700">
            <EditorContent editor={editor} />
        </div>
    );
}
