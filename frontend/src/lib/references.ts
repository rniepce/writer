// API client for Reference Documents (Narrative Map & Writing Style)

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:8001';

export interface ReferenceDocSummary {
    id: number;
    doc_type: 'narrative_map' | 'writing_style';
    filename: string | null;
    preview: string;
    updated_at: string;
}

export interface ReferenceDoc {
    id: number;
    project_id: number;
    doc_type: string;
    content: string;
    filename: string | null;
    created_at: string;
    updated_at: string;
}

export async function listReferenceDocs(projectId: number): Promise<ReferenceDocSummary[]> {
    const response = await fetch(`${API_BASE_URL}/references?project_id=${projectId}`);
    if (!response.ok) throw new Error('Erro ao listar documentos de referência');
    return response.json();
}

export async function getReferenceDoc(projectId: number, docType: string): Promise<ReferenceDoc | null> {
    const response = await fetch(`${API_BASE_URL}/references/${docType}?project_id=${projectId}`);
    if (!response.ok) throw new Error('Erro ao buscar documento de referência');
    const data = await response.json();
    return data;
}

export async function upsertReferenceDoc(
    projectId: number,
    docType: string,
    content: string,
    filename?: string
): Promise<ReferenceDoc> {
    const response = await fetch(`${API_BASE_URL}/references/${docType}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            project_id: projectId,
            content,
            filename: filename || null,
        }),
    });
    if (!response.ok) throw new Error('Erro ao salvar documento de referência');
    return response.json();
}

export async function deleteReferenceDoc(projectId: number, docType: string): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/references/${docType}?project_id=${projectId}`, {
        method: 'DELETE',
    });
    if (!response.ok) throw new Error('Erro ao remover documento de referência');
}
