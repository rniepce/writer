// API Client for Chapter Cards

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:8001';

// Types
export interface ChapterCard {
    id: number;
    title: string;
    order: number;
    word_count: number;
    color: string | null;
    preview: string;
    updated_at: string;
}

export interface Chapter {
    id: number;
    title: string;
    content: string;
    order: number;
    word_count: number;
    color: string | null;
    created_at: string;
    updated_at: string;
    project_id: number | null;
}

export interface ChapterCreate {
    title?: string;
    content?: string;
    project_id?: number;
    color?: string;
}

export interface ChapterUpdate {
    title?: string;
    content?: string;
    color?: string;
}

// API Functions

export async function listChapters(): Promise<ChapterCard[]> {
    const response = await fetch(`${API_BASE_URL}/chapters`);
    if (!response.ok) {
        throw new Error('Falha ao carregar capítulos');
    }
    return response.json();
}

export async function getChapter(id: number): Promise<Chapter> {
    const response = await fetch(`${API_BASE_URL}/chapters/${id}`);
    if (!response.ok) {
        throw new Error('Capítulo não encontrado');
    }
    return response.json();
}

export async function createChapter(data: ChapterCreate = {}): Promise<Chapter> {
    const response = await fetch(`${API_BASE_URL}/chapters`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });
    if (!response.ok) {
        throw new Error('Falha ao criar capítulo');
    }
    return response.json();
}

export async function updateChapter(id: number, data: ChapterUpdate): Promise<Chapter> {
    const response = await fetch(`${API_BASE_URL}/chapters/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });
    if (!response.ok) {
        throw new Error('Falha ao salvar capítulo');
    }
    return response.json();
}

export async function deleteChapter(id: number): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/chapters/${id}`, {
        method: 'DELETE',
    });
    if (!response.ok) {
        throw new Error('Falha ao remover capítulo');
    }
}

export async function reorderChapters(chapterIds: number[]): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/chapters/reorder`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ chapter_ids: chapterIds }),
    });
    if (!response.ok) {
        throw new Error('Falha ao reordenar capítulos');
    }
}
