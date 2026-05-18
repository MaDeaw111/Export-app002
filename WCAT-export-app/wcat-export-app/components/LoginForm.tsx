'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { Button } from '@/components/ui/button';

export default function LoginForm() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) alert(error.message);
    else router.push('/dashboard');
    setLoading(false);
  };

  return (
    <form onSubmit={handleLogin} className="flex flex-col gap-4 p-8 border rounded-lg max-w-sm mx-auto mt-20">
      <h1 className="text-2xl font-bold">Login</h1>
      <input type="email" placeholder="Email" onChange={(e) => setEmail(e.target.value)} className="p-2 border rounded" required />
      <input type="password" placeholder="Password" onChange={(e) => setPassword(e.target.value)} className="p-2 border rounded" required />
      <Button disabled={loading}>{loading ? 'Logging in...' : 'Login'}</Button>
    </form>
  );
}
