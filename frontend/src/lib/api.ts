// API Client for Ghost Writer Editorial Council

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:8001';

// Types matching backend Pydantic models
export interface AnalysisResult {
    model: string;
    focus: string;
    analysis: string;
    suggestions: string[];
}

export interface PolishReport {
    claude_style: AnalysisResult;
    gemini_coherence: AnalysisResult;
    gpt_structure: AnalysisResult;
    consensus: string;
    divergence: string;
    verdict: string;
}

export interface PolishRequest {
    text: string;
    manuscript_context: string;
    project_name?: string;
    style_ref?: string;
    chapter?: string;
    scene?: string;
    emotional_state?: string;
}

export interface ConsistencyAlert {
    type: string;
    severity: 'low' | 'medium' | 'high';
    message: string;
    suggestion?: string;
}

export interface FlowRequest {
    current_text: string;
    manuscript_context: string;
}

export interface DoubtRequest {
    question: string;
    text_context: string;
}

// API Functions
export async function polishText(request: PolishRequest): Promise<PolishReport> {
    const response = await fetch(`${API_BASE_URL}/council/polish`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(request),
    });

    if (!response.ok) {
        const error = await response.json();
        throw new Error(error.detail || 'Failed to polish text');
    }

    return response.json();
}

export async function flowCheck(request: FlowRequest): Promise<ConsistencyAlert | null> {
    const response = await fetch(`${API_BASE_URL}/council/flow`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(request),
    });

    if (!response.ok) {
        const error = await response.json();
        throw new Error(error.detail || 'Failed to check flow');
    }

    return response.json();
}

export async function doubtAnalysis(request: DoubtRequest): Promise<AnalysisResult> {
    const response = await fetch(`${API_BASE_URL}/council/doubt`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(request),
    });

    if (!response.ok) {
        const error = await response.json();
        throw new Error(error.detail || 'Failed to analyze doubt');
    }

    return response.json();
}
