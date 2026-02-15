// API Client for Projects (Books)

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:8001';

// Types
export interface ProjectCard {
    id: number;
    title: string;
    chapter_count: number;
    created_at: string;
}

export interface Project {
    id: number;
    title: string;
    description: string | null;
    created_at: string;
    chapter_count: number;
}

export interface ProjectCreate {
    title: string;
    description?: string;
}

export interface ProjectUpdate {
    title?: string;
    description?: string;
}

// API Functions

export async function listProjects(): Promise<ProjectCard[]> {
    const response = await fetch(`${API_BASE_URL}/projects`);
    if (!response.ok) {
        throw new Error('Falha ao carregar projetos');
    }
    return response.json();
}

export async function getProject(id: number): Promise<Project> {
    const response = await fetch(`${API_BASE_URL}/projects/${id}`);
    if (!response.ok) {
        throw new Error('Projeto não encontrado');
    }
    return response.json();
}

export async function createProject(data: ProjectCreate): Promise<Project> {
    const response = await fetch(`${API_BASE_URL}/projects`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });
    if (!response.ok) {
        throw new Error('Falha ao criar projeto');
    }
    return response.json();
}

export async function updateProject(id: number, data: ProjectUpdate): Promise<Project> {
    const response = await fetch(`${API_BASE_URL}/projects/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });
    if (!response.ok) {
        throw new Error('Falha ao atualizar projeto');
    }
    return response.json();
}

export async function deleteProject(id: number): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/projects/${id}`, {
        method: 'DELETE',
    });
    if (!response.ok) {
        throw new Error('Falha ao remover projeto');
    }
}

export async function exportProject(id: number, format: 'docx' | 'pdf'): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/projects/${id}/export?format=${format}`);
    if (!response.ok) {
        throw new Error('Falha ao exportar projeto');
    }

    const blob = await response.blob();
    const disposition = response.headers.get('Content-Disposition');
    let filename = `projeto.${format}`;
    if (disposition) {
        const match = disposition.match(/filename="?([^"]+)"?/);
        if (match) filename = match[1];
    }

    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

export async function saveProjectOffline(id: number): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/projects/${id}/save`);
    if (!response.ok) {
        throw new Error('Falha ao salvar projeto offline');
    }

    const blob = await response.blob();
    const disposition = response.headers.get('Content-Disposition');
    let filename = 'projeto.writerproject';
    if (disposition) {
        const match = disposition.match(/filename="?([^"]+)"?/);
        if (match) filename = match[1];
    }

    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

export async function importProject(file: File): Promise<Project> {
    const formData = new FormData();
    formData.append('file', file);

    const response = await fetch(`${API_BASE_URL}/projects/import`, {
        method: 'POST',
        body: formData,
    });
    if (!response.ok) {
        const error = await response.json().catch(() => ({ detail: 'Erro desconhecido' }));
        throw new Error(error.detail || 'Falha ao importar projeto');
    }
    return response.json();
}

