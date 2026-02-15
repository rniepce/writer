'use client';

import { useState, useEffect } from 'react';
import { useRef } from 'react';
import { FolderOpen, Plus, ChevronDown, Book, Download, Upload, Loader2, HardDrive, Trash2 } from 'lucide-react';
import { ProjectCard, listProjects, createProject, deleteProject, exportProject, saveProjectOffline, importProject } from '@/lib/projects';

interface ProjectSelectorProps {
    activeProjectId: number | null;
    onSelectProject: (projectId: number | null) => void;
}

export default function ProjectSelector({
    activeProjectId,
    onSelectProject
}: ProjectSelectorProps) {
    const [projects, setProjects] = useState<ProjectCard[]>([]);
    const [isOpen, setIsOpen] = useState(false);
    const [isCreating, setIsCreating] = useState(false);
    const [newProjectTitle, setNewProjectTitle] = useState('');
    const [showNewForm, setShowNewForm] = useState(false);
    const [showExportMenu, setShowExportMenu] = useState(false);
    const [isExporting, setIsExporting] = useState(false);
    const [isImporting, setIsImporting] = useState(false);
    const [confirmDeleteId, setConfirmDeleteId] = useState<number | null>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);

    const loadProjects = async (retries = 5) => {
        for (let i = 0; i < retries; i++) {
            try {
                const data = await listProjects();
                setProjects(data);
                return;
            } catch (error) {
                if (i < retries - 1) {
                    await new Promise(r => setTimeout(r, 1000));
                } else {
                    console.error('Erro ao carregar projetos:', error);
                }
            }
        }
    };

    useEffect(() => {
        loadProjects();
    }, []);

    const activeProject = projects.find(p => p.id === activeProjectId);

    const handleCreateProject = async () => {
        if (!newProjectTitle.trim()) return;

        setIsCreating(true);
        try {
            const newProject = await createProject({ title: newProjectTitle.trim() });
            await loadProjects();
            onSelectProject(newProject.id);
            setNewProjectTitle('');
            setShowNewForm(false);
            setIsOpen(false);
        } catch (error) {
            console.error('Erro ao criar projeto:', error);
        } finally {
            setIsCreating(false);
        }
    };

    const handleExport = async (format: 'docx' | 'pdf') => {
        if (!activeProjectId) return;

        setIsExporting(true);
        try {
            await exportProject(activeProjectId, format);
        } catch (error) {
            console.error('Erro ao exportar projeto:', error);
            alert('Erro ao exportar projeto. Tente novamente.');
        } finally {
            setIsExporting(false);
            setShowExportMenu(false);
        }
    };

    const handleSaveOffline = async () => {
        if (!activeProjectId) return;

        setIsExporting(true);
        try {
            await saveProjectOffline(activeProjectId);
        } catch (error) {
            console.error('Erro ao salvar projeto offline:', error);
            alert('Erro ao salvar projeto. Tente novamente.');
        } finally {
            setIsExporting(false);
            setShowExportMenu(false);
        }
    };

    const handleImport = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        setIsImporting(true);
        try {
            const imported = await importProject(file);
            await loadProjects();
            onSelectProject(imported.id);
            setIsOpen(false);
        } catch (error) {
            console.error('Erro ao importar projeto:', error);
            alert('Erro ao importar projeto. Verifique se o arquivo é válido.');
        } finally {
            setIsImporting(false);
            // Reset file input so the same file can be re-selected
            if (fileInputRef.current) fileInputRef.current.value = '';
        }
    };

    const handleKeyDown = (e: React.KeyboardEvent) => {
        if (e.key === 'Enter') {
            handleCreateProject();
        } else if (e.key === 'Escape') {
            setShowNewForm(false);
            setNewProjectTitle('');
        }
    };

    const handleDeleteProject = (e: React.MouseEvent, projectId: number) => {
        e.stopPropagation();
        e.preventDefault();
        // Toggle inline confirmation instead of using window.confirm (broken in WebView)
        setConfirmDeleteId(prev => prev === projectId ? null : projectId);
    };

    const executeDelete = async (projectId: number) => {
        setConfirmDeleteId(null);
        try {
            await deleteProject(projectId);
            const updatedProjects = await listProjects();
            setProjects(updatedProjects);
            if (activeProjectId === projectId) {
                if (updatedProjects.length > 0) {
                    onSelectProject(updatedProjects[0].id);
                } else {
                    onSelectProject(null);
                }
            }
        } catch (error) {
            console.error('Erro ao excluir projeto:', error);
        }
    };

    return (
        <div className="fixed top-4 left-1/2 -translate-x-1/2 z-30">
            <div className="relative flex items-center gap-2">
                {/* Current Project Button */}
                <button
                    onClick={() => { setIsOpen(!isOpen); setShowExportMenu(false); }}
                    className="
                        flex items-center gap-2 px-4 py-2
                        bg-white/90 backdrop-blur-sm
                        border border-stone-200 rounded-full
                        shadow-sm hover:shadow-md
                        transition-all duration-200
                        text-stone-700 font-medium
                    "
                >
                    <Book size={16} className="text-amber-600" />
                    <span className="max-w-[200px] truncate">
                        {activeProject?.title || 'Selecione um projeto'}
                    </span>
                    <ChevronDown
                        size={16}
                        className={`text-stone-400 transition-transform ${isOpen ? 'rotate-180' : ''}`}
                    />
                </button>

                {/* Export Button */}
                {activeProjectId && (
                    <div className="relative">
                        <button
                            onClick={() => { setShowExportMenu(!showExportMenu); setIsOpen(false); }}
                            disabled={isExporting}
                            className="
                                flex items-center gap-1.5 px-3 py-2
                                bg-white/90 backdrop-blur-sm
                                border border-stone-200 rounded-full
                                shadow-sm hover:shadow-md
                                transition-all duration-200
                                text-stone-600 hover:text-amber-700
                                disabled:opacity-50 disabled:cursor-not-allowed
                            "
                            title="Exportar projeto"
                        >
                            {isExporting ? (
                                <Loader2 size={16} className="animate-spin" />
                            ) : (
                                <Download size={16} />
                            )}
                            <span className="text-sm font-medium hidden sm:inline">
                                {isExporting ? 'Exportando...' : 'Exportar'}
                            </span>
                        </button>

                        {/* Export Format Menu */}
                        {showExportMenu && (
                            <div className="
                                absolute top-full right-0 mt-2
                                w-48 bg-white rounded-xl shadow-xl border border-stone-200
                                overflow-hidden
                            ">
                                <div className="p-1.5">
                                    <p className="px-3 py-1.5 text-xs font-semibold text-stone-400 uppercase tracking-wider">
                                        Formato
                                    </p>
                                    <button
                                        onClick={() => handleExport('docx')}
                                        className="
                                            w-full text-left px-3 py-2.5 rounded-lg
                                            flex items-center gap-3
                                            hover:bg-amber-50 text-stone-700
                                            transition-colors duration-150
                                        "
                                    >
                                        <span className="text-xs font-mono bg-blue-100 text-blue-700 px-2 py-0.5 rounded">
                                            .docx
                                        </span>
                                        <span className="text-sm">Word</span>
                                    </button>
                                    <button
                                        onClick={() => handleExport('pdf')}
                                        className="
                                            w-full text-left px-3 py-2.5 rounded-lg
                                            flex items-center gap-3
                                            hover:bg-amber-50 text-stone-700
                                            transition-colors duration-150
                                        "
                                    >
                                        <span className="text-xs font-mono bg-red-100 text-red-700 px-2 py-0.5 rounded">
                                            .pdf
                                        </span>
                                        <span className="text-sm">PDF</span>
                                    </button>
                                    <div className="border-t border-stone-100 my-1" />
                                    <button
                                        onClick={handleSaveOffline}
                                        className="
                                            w-full text-left px-3 py-2.5 rounded-lg
                                            flex items-center gap-3
                                            hover:bg-emerald-50 text-stone-700
                                            transition-colors duration-150
                                        "
                                    >
                                        <HardDrive size={14} className="text-emerald-600" />
                                        <span className="text-sm">Salvar Offline</span>
                                    </button>
                                </div>
                            </div>
                        )}
                    </div>
                )}

                {/* Dropdown */}
                {isOpen && (
                    <div className="
                        absolute top-full left-1/2 -translate-x-1/2 mt-2
                        w-72 bg-white rounded-xl shadow-xl border border-stone-200
                        overflow-hidden
                    ">
                        {/* Projects List */}
                        <div className="max-h-64 overflow-y-auto p-2">
                            {projects.length === 0 ? (
                                <div className="text-center py-6 text-stone-500">
                                    <FolderOpen size={24} className="mx-auto mb-2 opacity-50" />
                                    <p className="text-sm">Nenhum projeto ainda</p>
                                </div>
                            ) : (
                                projects.map((project) => (
                                    <div
                                        key={project.id}
                                        className={`
                                            w-full text-left px-3 py-2.5 rounded-lg
                                            flex items-center gap-3
                                            transition-colors duration-150 cursor-pointer group
                                            ${project.id === activeProjectId
                                                ? 'bg-amber-100 text-amber-900'
                                                : 'hover:bg-stone-100 text-stone-700'}
                                        `}
                                        onClick={() => {
                                            onSelectProject(project.id);
                                            setIsOpen(false);
                                        }}
                                    >
                                        <Book size={16} className={
                                            project.id === activeProjectId
                                                ? 'text-amber-600'
                                                : 'text-stone-400'
                                        } />
                                        <div className="flex-1 min-w-0">
                                            <p className="font-medium truncate">{project.title}</p>
                                            <p className="text-xs text-stone-500">
                                                {project.chapter_count} capítulo{project.chapter_count !== 1 ? 's' : ''}
                                            </p>
                                        </div>
                                        {confirmDeleteId === project.id ? (
                                            <div className="flex items-center gap-1 flex-shrink-0" onClick={(e) => e.stopPropagation()}>
                                                <button
                                                    onClick={(e) => { e.stopPropagation(); executeDelete(project.id); }}
                                                    className="
                                                        px-2 py-1 rounded-md text-xs font-medium
                                                        bg-red-500 text-white hover:bg-red-600
                                                        transition-all duration-150
                                                    "
                                                >
                                                    Excluir?
                                                </button>
                                                <button
                                                    onClick={(e) => { e.stopPropagation(); setConfirmDeleteId(null); }}
                                                    className="
                                                        px-2 py-1 rounded-md text-xs
                                                        text-stone-500 hover:bg-stone-200
                                                        transition-all duration-150
                                                    "
                                                >
                                                    Não
                                                </button>
                                            </div>
                                        ) : (
                                            <button
                                                onClick={(e) => handleDeleteProject(e, project.id)}
                                                className="
                                                    p-1.5 rounded-md
                                                    text-stone-300 hover:bg-red-100 hover:text-red-600
                                                    transition-all duration-150
                                                    flex-shrink-0
                                                "
                                                title="Excluir projeto"
                                            >
                                                <Trash2 size={14} />
                                            </button>
                                        )}
                                    </div>
                                ))
                            )}
                        </div>

                        {/* Divider */}
                        <div className="border-t border-stone-200" />

                        {/* New Project Form */}
                        {showNewForm ? (
                            <div className="p-3">
                                <input
                                    type="text"
                                    value={newProjectTitle}
                                    onChange={(e) => setNewProjectTitle(e.target.value)}
                                    onKeyDown={handleKeyDown}
                                    placeholder="Nome do projeto..."
                                    autoFocus
                                    className="
                                        w-full px-3 py-2 text-sm
                                        border border-stone-300 rounded-lg
                                        focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-transparent
                                    "
                                />
                                <div className="flex gap-2 mt-2">
                                    <button
                                        onClick={handleCreateProject}
                                        disabled={isCreating || !newProjectTitle.trim()}
                                        className="
                                            flex-1 py-2 bg-amber-600 text-white text-sm font-medium
                                            rounded-lg hover:bg-amber-700 transition-colors
                                            disabled:opacity-50 disabled:cursor-not-allowed
                                        "
                                    >
                                        {isCreating ? 'Criando...' : 'Criar'}
                                    </button>
                                    <button
                                        onClick={() => {
                                            setShowNewForm(false);
                                            setNewProjectTitle('');
                                        }}
                                        className="
                                            px-4 py-2 text-sm text-stone-600
                                            rounded-lg hover:bg-stone-100 transition-colors
                                        "
                                    >
                                        Cancelar
                                    </button>
                                </div>
                            </div>
                        ) : (
                            <div className="flex flex-col">
                                <button
                                    onClick={() => setShowNewForm(true)}
                                    className="
                                        w-full px-4 py-3 flex items-center gap-2
                                        text-amber-700 hover:bg-amber-50
                                        transition-colors duration-150
                                    "
                                >
                                    <Plus size={18} />
                                    <span className="font-medium">Novo Projeto</span>
                                </button>
                                <button
                                    onClick={() => fileInputRef.current?.click()}
                                    disabled={isImporting}
                                    className="
                                        w-full px-4 py-3 flex items-center gap-2
                                        text-emerald-700 hover:bg-emerald-50
                                        transition-colors duration-150
                                        disabled:opacity-50 disabled:cursor-not-allowed
                                    "
                                >
                                    <Upload size={18} />
                                    <span className="font-medium">
                                        {isImporting ? 'Importando...' : 'Importar Projeto'}
                                    </span>
                                </button>
                                <input
                                    ref={fileInputRef}
                                    type="file"
                                    accept=".writerproject"
                                    onChange={handleImport}
                                    className="hidden"
                                />
                            </div>
                        )}
                    </div>
                )}
            </div>

            {/* Click outside to close */}
            {(isOpen || showExportMenu) && (
                <div
                    className="fixed inset-0 -z-10"
                    onClick={() => { setIsOpen(false); setShowExportMenu(false); }}
                />
            )}
        </div>
    );
}
