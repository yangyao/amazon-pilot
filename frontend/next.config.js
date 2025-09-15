/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  experimental: {
    appDir: true,
  },
  env: {
    API_BASE_URL: process.env.API_BASE_URL || 'http://localhost:8888',
  },
  async rewrites() {
    const target = process.env.GATEWAY_URL || 'http://amazon-pilot-gateway:8080'
    return [
      {
        source: '/api/:path*',
        destination: `${target}/api/:path*`,
      },
    ]
  },
}
