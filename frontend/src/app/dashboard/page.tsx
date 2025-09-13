'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Cookies from 'js-cookie'

import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { authAPI, type User } from '@/lib/api'

export default function DashboardPage() {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const router = useRouter()

  useEffect(() => {
    const token = Cookies.get('access_token')
    if (!token) {
      router.push('/auth/login')
      return
    }

    // 获取用户资料
    authAPI.getProfile()
      .then((response) => {
        setUser(response.user)
      })
      .catch((error) => {
        console.error('Failed to get profile:', error)
        // Token可能过期，跳转到登录页
        Cookies.remove('access_token')
        Cookies.remove('user_info')
        router.push('/auth/login')
      })
      .finally(() => {
        setLoading(false)
      })
  }, [router])

  const handleLogout = () => {
    Cookies.remove('access_token')
    Cookies.remove('user_info')
    router.push('/')
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-gray-900"></div>
          <p className="mt-4">Loading...</p>
        </div>
      </div>
    )
  }

  if (!user) {
    return null // 会被重定向到登录页
  }

  return (
    <div className="container mx-auto py-8">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold">Dashboard</h1>
          <p className="text-gray-600">Welcome back, {user.email}</p>
        </div>
        <Button onClick={handleLogout} variant="outline">
          Logout
        </Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>User Profile</CardTitle>
            <CardDescription>Your account information</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div><strong>Email:</strong> {user.email}</div>
              <div><strong>Company:</strong> {user.company_name || 'Not set'}</div>
              <div><strong>Plan:</strong> {user.plan}</div>
              <div><strong>Status:</strong> {user.is_active ? 'Active' : 'Inactive'}</div>
              <div><strong>Member since:</strong> {new Date(user.created_at).toLocaleDateString()}</div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Product Tracking</CardTitle>
            <CardDescription>Monitor your Amazon products</CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-gray-600">Track ASIN performance, price changes, and BSR rankings.</p>
            <Button 
              className="mt-4 w-full" 
              onClick={() => router.push('/products')}
            >
              Manage Products
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Competitor Analysis</CardTitle>
            <CardDescription>Analyze your competition</CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-gray-600">Compare your products with competitors and get insights.</p>
            <Button 
              className="mt-4 w-full" 
              onClick={() => router.push('/competitors')}
            >
              View Analysis
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>AI Optimization</CardTitle>
            <CardDescription>AI-powered suggestions</CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-gray-600">Get optimization recommendations for your listings.</p>
            <Button 
              className="mt-4 w-full" 
              onClick={() => router.push('/optimization')}
            >
              Get Suggestions
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>System Operations</CardTitle>
            <CardDescription>Monitor and manage system</CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-gray-600">View system status, logs, and manage services.</p>
            <Button 
              className="mt-4 w-full" 
              onClick={() => router.push('/ops')}
            >
              System Dashboard
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>API Usage</CardTitle>
            <CardDescription>Monitor your API usage</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span>Plan:</span>
                <span className="font-medium">{user.plan}</span>
              </div>
              <div className="flex justify-between">
                <span>Rate Limit:</span>
                <span className="font-medium">
                  {user.plan === 'basic' ? '100' : user.plan === 'premium' ? '500' : '2000'} req/min
                </span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}