import Link from 'next/link'

export default function HomePage() {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen py-2">
      <main className="flex flex-col items-center justify-center w-full flex-1 px-20 text-center">
        <h1 className="text-6xl font-bold">
          Welcome to{' '}
          <span className="text-blue-600">Amazon Pilot</span>
        </h1>

        <p className="mt-3 text-2xl">
          Amazon seller product monitoring and optimization tool
        </p>

        <div className="flex mt-6 space-x-4">
          <Link
            href="/auth/login"
            className="px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 transition-colors"
          >
            Login
          </Link>
          <Link
            href="/auth/register"
            className="px-6 py-3 border border-gray-300 text-base font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 transition-colors"
          >
            Register
          </Link>
        </div>

        <div className="mt-8 grid grid-cols-1 md:grid-cols-3 gap-6 max-w-4xl">
          <div className="p-6 border rounded-lg">
            <h3 className="text-lg font-semibold">Product Tracking</h3>
            <p className="mt-2 text-gray-600">
              Monitor your Amazon products in real-time
            </p>
          </div>
          <div className="p-6 border rounded-lg">
            <h3 className="text-lg font-semibold">Competitor Analysis</h3>
            <p className="mt-2 text-gray-600">
              Analyze your competitors and market trends
            </p>
          </div>
          <div className="p-6 border rounded-lg">
            <h3 className="text-lg font-semibold">Optimization</h3>
            <p className="mt-2 text-gray-600">
              Get AI-powered optimization suggestions
            </p>
          </div>
        </div>
      </main>
    </div>
  )
}