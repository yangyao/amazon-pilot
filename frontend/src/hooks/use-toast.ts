// 简化版本的 toast hook
type ToastProps = {
  title?: string
  description?: string
  variant?: "default" | "destructive"
}

function useToast() {
  const toast = ({ title, description, variant }: ToastProps) => {
    // 简单的 alert 实现，用于演示
    const message = title ? `${title}: ${description || ''}` : description || ''
    if (variant === 'destructive') {
      alert(`❌ ${message}`)
    } else {
      alert(`✅ ${message}`)
    }
  }

  return { toast }
}

export { useToast }