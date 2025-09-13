'use client'

import { useState, useEffect } from 'react'
import { useRouter, usePathname } from 'next/navigation'
import Link from 'next/link'
import Cookies from 'js-cookie'

import { Button } from '@/components/ui/button'
import { authAPI, type User } from '@/lib/api'

export default function Navigation() {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const router = useRouter()
  const pathname = usePathname()

  useEffect(() => {
    const token = Cookies.get('access_token')
    if (!token) {
      setLoading(false)
      return
    }

    // 获取用户信息
    authAPI.getProfile()
      .then((response) => {
        setUser(response.user)
      })
      .catch((error) => {
        console.error('Failed to get profile:', error)
        // Token可能过期，清除
        Cookies.remove('access_token')
        Cookies.remove('user_info')
      })
      .finally(() => {
        setLoading(false)
      })
  }, [])

  const handleLogout = async () => {
    try {
      await authAPI.logout()
    } catch (error) {
      console.error('Logout error:', error)
    } finally {
      // 无论后端响应如何，都清除前端token
      Cookies.remove('access_token')
      Cookies.remove('user_info')
      router.push('/')
    }
  }

  // 如果在认证页面，不显示导航
  if (pathname?.startsWith('/auth')) {
    return null
  }

  return (
    <nav className="border-b bg-white">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <div className="flex items-center space-x-4">
            <Link href="/" className="text-xl font-bold text-blue-600">
              Amazon Pilot
            </Link>
          </div>

          {/* Navigation Links */}
          {user ? (
            <div className="flex items-center space-x-6">
              <Link 
                href="/dashboard" 
                className={`text-gray-700 hover:text-blue-600 ${
                  pathname === '/dashboard' ? 'font-medium text-blue-600' : ''
                }`}
              >
                Dashboard
              </Link>
              <Link 
                href="/products" 
                className={`text-gray-700 hover:text-blue-600 ${
                  pathname === '/products' ? 'font-medium text-blue-600' : ''
                }`}
              >
                Products
              </Link>
              <Link 
                href="/competitors" 
                className={`text-gray-700 hover:text-blue-600 ${
                  pathname === '/competitors' ? 'font-medium text-blue-600' : ''
                }`}
              >
                Competitors
              </Link>
              <Link 
                href="/optimization" 
                className={`text-gray-700 hover:text-blue-600 ${
                  pathname === '/optimization' ? 'font-medium text-blue-600' : ''
                }`}
              >
                Optimization
              </Link>
              <Link 
                href="/ops" 
                className={`text-gray-700 hover:text-blue-600 ${
                  pathname === '/ops' ? 'font-medium text-blue-600' : ''
                }`}
              >
                System Ops
              </Link>
              
              {/* User Menu */}
              <div className="flex items-center space-x-4">
                <span className="text-sm text-gray-600">
                  {user.email}
                </span>
                <Button 
                  variant="outline" 
                  size="sm"
                  onClick={handleLogout}
                  disabled={loading}
                >
                  Logout
                </Button>
              </div>
            </div>
          ) : (
            <div className="flex items-center space-x-4">
              <Link href="/auth/login">
                <Button variant="outline" size="sm">
                  Login
                </Button>
              </Link>
              <Link href="/auth/register">
                <Button size="sm">
                  Register
                </Button>
              </Link>
            </div>
          )}
        </div>
      </div>
    </nav>
  )
}