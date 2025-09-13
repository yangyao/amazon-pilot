'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { authAPI } from '@/lib/api'

const registerSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  confirmPassword: z.string(),
  company_name: z.string().optional(),
  plan: z.enum(['basic', 'premium', 'enterprise']).default('basic'),
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ["confirmPassword"],
})

type RegisterFormData = z.infer<typeof registerSchema>

export default function RegisterPage() {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string>('')
  const [success, setSuccess] = useState(false)
  const router = useRouter()

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<RegisterFormData>({
    resolver: zodResolver(registerSchema),
  })

  const onSubmit = async (data: RegisterFormData) => {
    setIsLoading(true)
    setError('')

    try {
      const { confirmPassword, ...registerData } = data
      await authAPI.register(registerData)
      
      setSuccess(true)
      
      // 注册成功后等待2秒然后跳转到登录页
      setTimeout(() => {
        router.push('/auth/login')
      }, 2000)
    } catch (err: any) {
      console.error('Registration error:', err)
      
      if (err.response?.data?.error) {
        const errorData = err.response.data.error
        if (errorData.details && errorData.details.length > 0) {
          // 显示字段级错误
          const fieldErrors = errorData.details.map((d: any) => `${d.field}: ${d.message}`).join(', ')
          setError(`${errorData.message}: ${fieldErrors}`)
        } else {
          setError(errorData.message)
        }
      } else {
        setError('Registration failed. Please try again.')
      }
    } finally {
      setIsLoading(false)
    }
  }

  if (success) {
    return (
      <div className="container relative h-screen flex-col items-center justify-center grid lg:max-w-none lg:px-0">
        <div className="lg:p-8">
          <div className="mx-auto flex w-full flex-col justify-center space-y-6 sm:w-[350px]">
            <Card>
              <CardHeader>
                <CardTitle>Registration Successful!</CardTitle>
                <CardDescription>
                  Your account has been created successfully. Redirecting to login...
                </CardDescription>
              </CardHeader>
            </Card>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="container relative h-screen flex-col items-center justify-center grid lg:max-w-none lg:grid-cols-2 lg:px-0">
      <div className="relative hidden h-full flex-col bg-muted p-10 text-white lg:flex dark:border-r">
        <div className="absolute inset-0 bg-zinc-900" />
        <div className="relative z-20 flex items-center text-lg font-medium">
          Amazon Pilot
        </div>
        <div className="relative z-20 mt-auto">
          <blockquote className="space-y-2">
            <p className="text-lg">
              "Join thousands of Amazon sellers who are already optimizing their business with Amazon Pilot."
            </p>
            <footer className="text-sm">Start your journey today</footer>
          </blockquote>
        </div>
      </div>
      <div className="lg:p-8">
        <div className="mx-auto flex w-full flex-col justify-center space-y-6 sm:w-[350px]">
          <Card>
            <CardHeader>
              <CardTitle>Create an account</CardTitle>
              <CardDescription>
                Enter your details below to create your account
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                <div className="space-y-2">
                  <Input
                    {...register('email')}
                    type="email"
                    placeholder="Email"
                    disabled={isLoading}
                  />
                  {errors.email && (
                    <p className="text-sm text-red-500">{errors.email.message}</p>
                  )}
                </div>

                <div className="space-y-2">
                  <Input
                    {...register('company_name')}
                    type="text"
                    placeholder="Company Name (optional)"
                    disabled={isLoading}
                  />
                  {errors.company_name && (
                    <p className="text-sm text-red-500">{errors.company_name.message}</p>
                  )}
                </div>
                
                <div className="space-y-2">
                  <Input
                    {...register('password')}
                    type="password"
                    placeholder="Password"
                    disabled={isLoading}
                  />
                  {errors.password && (
                    <p className="text-sm text-red-500">{errors.password.message}</p>
                  )}
                </div>

                <div className="space-y-2">
                  <Input
                    {...register('confirmPassword')}
                    type="password"
                    placeholder="Confirm Password"
                    disabled={isLoading}
                  />
                  {errors.confirmPassword && (
                    <p className="text-sm text-red-500">{errors.confirmPassword.message}</p>
                  )}
                </div>

                <div className="space-y-2">
                  <select
                    {...register('plan')}
                    className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background"
                    disabled={isLoading}
                  >
                    <option value="basic">Basic Plan (Free)</option>
                    <option value="premium">Premium Plan</option>
                    <option value="enterprise">Enterprise Plan</option>
                  </select>
                  {errors.plan && (
                    <p className="text-sm text-red-500">{errors.plan.message}</p>
                  )}
                </div>

                {error && (
                  <div className="text-sm text-red-500 bg-red-50 p-3 rounded-md">
                    {error}
                  </div>
                )}

                <Button type="submit" className="w-full" disabled={isLoading}>
                  {isLoading ? 'Creating account...' : 'Create account'}
                </Button>
              </form>

              <div className="mt-4 text-center text-sm">
                Already have an account?{' '}
                <Link href="/auth/login" className="text-blue-600 hover:underline">
                  Sign in here
                </Link>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}