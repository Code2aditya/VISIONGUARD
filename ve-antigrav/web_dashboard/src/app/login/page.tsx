"use client";

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Shield, Car, KeyRound } from 'lucide-react';
import { motion } from 'framer-motion';

export default function LoginPage() {
  const [vehicleId, setVehicleId] = useState('');
  const [accessId, setAccessId] = useState('');
  const [error, setError] = useState('');
  const router = useRouter();

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    if (vehicleId === 'VG-001' && accessId === 'admin123') {
      router.push('/dashboard');
    } else {
      setError('Invalid Vehicle Number or Access ID');
    }
  };

  return (
    <div className="min-h-screen bg-neutral-950 flex items-center justify-center p-4">
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute -top-40 -right-40 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl"></div>
        <div className="absolute -bottom-40 -left-40 w-96 h-96 bg-purple-500/10 rounded-full blur-3xl"></div>
      </div>
      
      <motion.div 
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-md relative z-10"
      >
        <div className="bg-neutral-900/50 backdrop-blur-xl rounded-3xl p-8 border border-neutral-800 shadow-2xl">
          <div className="flex flex-col items-center mb-8">
            <div className="w-16 h-16 bg-blue-500/20 rounded-2xl flex items-center justify-center mb-4 border border-blue-500/30">
              <Shield className="w-8 h-8 text-blue-400" />
            </div>
            <h1 className="text-3xl font-bold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
              VisionGuard
            </h1>
            <p className="text-neutral-400 mt-2 text-sm text-center">
              Secure Fleet & Driver Monitoring System
            </p>
          </div>

          <form onSubmit={handleLogin} className="space-y-6">
            <div>
              <label className="text-sm font-medium text-neutral-300 mb-2 block">
                Vehicle Number
              </label>
              <div className="relative">
                <Car className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-500" />
                <input
                  type="text"
                  value={vehicleId}
                  onChange={(e) => setVehicleId(e.target.value)}
                  className="w-full bg-neutral-950/50 border border-neutral-800 rounded-xl py-3 pl-10 pr-4 text-white focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500/50 transition-all placeholder:text-neutral-600"
                  placeholder="e.g. VG-001"
                  required
                />
              </div>
            </div>

            <div>
              <label className="text-sm font-medium text-neutral-300 mb-2 block">
                Access ID
              </label>
              <div className="relative">
                <KeyRound className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-neutral-500" />
                <input
                  type="password"
                  value={accessId}
                  onChange={(e) => setAccessId(e.target.value)}
                  className="w-full bg-neutral-950/50 border border-neutral-800 rounded-xl py-3 pl-10 pr-4 text-white focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500/50 transition-all placeholder:text-neutral-600"
                  placeholder="Enter access code"
                  required
                />
              </div>
            </div>

            {error && (
              <motion.p 
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                className="text-red-400 text-sm text-center bg-red-400/10 py-2 rounded-lg"
              >
                {error}
              </motion.p>
            )}

            <button
              type="submit"
              className="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-500 hover:to-purple-500 text-white font-semibold py-3 rounded-xl transition-all active:scale-[0.98] shadow-lg shadow-blue-500/25"
            >
              Access System
            </button>
            <div className="text-center mt-4">
              <a href="/shop" className="text-sm text-blue-400 hover:text-blue-300 transition-colors">
                Learn more about VisionGuard &rarr;
              </a>
            </div>
          </form>
        </div>
      </motion.div>
    </div>
  );
}
