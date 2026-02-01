import ZenEditor from '@/components/Editor/ZenEditor';

export default function Home() {
    return (
        <main className="min-h-screen bg-paper-bg transition-colors duration-1000">
            <ZenEditor />

            {/* Ghost Panels (Hidden by default) */}
            <div className="fixed inset-y-0 left-0 w-12 hover:w-64 transition-all duration-300 opacity-0 hover:opacity-100 z-50">
                {/* Left Panel Content */}
            </div>

            <div className="fixed inset-y-0 right-0 w-12 hover:w-80 transition-all duration-300 opacity-0 hover:opacity-100 z-50">
                {/* Right Panel Content */}
            </div>
        </main>
    );
}
