export default function Loading() {
    return (
        <div className="min-h-screen bg-white flex items-center justify-center">
            <div className="text-center">
                <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-black mb-4"></div>
                <p className="text-gray-700">Loading...</p>
            </div>
        </div>
    );
}
