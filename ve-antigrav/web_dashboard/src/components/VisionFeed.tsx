"use client";

import { motion } from "framer-motion";
import { useEffect, useState } from "react";
import { Scan, Target, Activity, Zap } from "lucide-react";

export default function VisionFeed() {
  const [confidence, setConfidence] = useState(98.4);
  const [fps, setFps] = useState(60);

  useEffect(() => {
    const interval = setInterval(() => {
      setConfidence(98 + Math.random() * 1.5);
      setFps(58 + Math.floor(Math.random() * 5));
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="w-full h-full bg-neutral-950 rounded-3xl overflow-hidden relative border border-neutral-800 shadow-2xl group">
      {/* Background Simulating Driver View */}
      <div className="absolute inset-0 bg-[url('https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?q=80&w=2070&auto=format&fit=crop')] bg-cover bg-center opacity-40 grayscale group-hover:grayscale-0 transition-all duration-700"></div>
      <div className="absolute inset-0 bg-gradient-to-t from-neutral-950 via-transparent to-neutral-950/20"></div>

      {/* Retro-Futuristic Scanline Grid */}
      <div className="absolute inset-0 opacity-20 pointer-events-none" 
           style={{ backgroundImage: 'linear-gradient(rgba(18, 16, 16, 0) 50%, rgba(0, 0, 0, 0.25) 50%), linear-gradient(90deg, rgba(255, 0, 0, 0.06), rgba(0, 255, 0, 0.02), rgba(0, 0, 255, 0.06))', backgroundSize: '100% 2px, 3px 100%' }}>
      </div>

      {/* Scanning Line */}
      <motion.div 
        initial={{ top: 0 }}
        animate={{ top: "100%" }}
        transition={{ duration: 4, repeat: Infinity, ease: "linear" }}
        className="absolute left-0 right-0 h-[2px] bg-blue-500/30 shadow-[0_0_15px_rgba(59,130,246,0.5)] z-10"
      />

      {/* AI Telemetry Overlays */}
      <div className="absolute top-6 left-6 z-20 space-y-2">
        <div className="flex items-center gap-2 bg-neutral-950/80 backdrop-blur-md px-3 py-1.5 rounded-lg border border-neutral-800/50">
          <Activity className="w-3.5 h-3.5 text-blue-400" />
          <span className="text-[10px] font-mono text-neutral-300 uppercase tracking-widest">System: Online</span>
        </div>
        <div className="flex items-center gap-2 bg-neutral-950/80 backdrop-blur-md px-3 py-1.5 rounded-lg border border-neutral-800/50">
          <Zap className="w-3.5 h-3.5 text-yellow-400" />
          <span className="text-[10px] font-mono text-neutral-300 uppercase tracking-widest">Conf: {confidence.toFixed(1)}%</span>
        </div>
      </div>

      <div className="absolute top-6 right-6 z-20">
        <div className="bg-neutral-950/80 backdrop-blur-md px-3 py-1.5 rounded-lg border border-neutral-800/50">
          <span className="text-[10px] font-mono text-neutral-300 uppercase tracking-widest">{fps} FPS</span>
        </div>
      </div>

      {/* Detection Boxes (Animated) */}
      <motion.div 
        animate={{ 
          x: [0, 5, -5, 2, 0],
          y: [0, -3, 3, -1, 0],
          scale: [1, 1.01, 0.99, 1]
        }}
        transition={{ duration: 8, repeat: Infinity, ease: "easeInOut" }}
        className="absolute top-[30%] left-[40%] w-[20%] h-[30%] border border-blue-500/60 rounded-xl z-20 shadow-[0_0_10px_rgba(59,130,246,0.3)]"
      >
        <div className="absolute -top-6 left-0 flex items-center gap-2">
          <div className="w-2 h-2 bg-blue-500 rounded-full animate-pulse"></div>
          <span className="text-[10px] font-mono text-blue-400 font-bold uppercase textShadow-[0_0_5px_rgba(59,130,246,0.8)]">Target: Driver</span>
        </div>
        
        <div className="absolute top-0 left-0 w-2 h-2 border-t border-l border-blue-400"></div>
        <div className="absolute top-0 right-0 w-2 h-2 border-t border-r border-blue-400"></div>
        <div className="absolute bottom-0 left-0 w-2 h-2 border-b border-l border-blue-400"></div>
        <div className="absolute bottom-0 right-0 w-2 h-2 border-b border-r border-blue-400"></div>
      </motion.div>

       <motion.div 
        animate={{ 
          x: [0, 3, -2, 1, 0],
          y: [0, -2, 2, -1, 0],
        }}
        transition={{ duration: 5, repeat: Infinity, ease: "easeInOut" }}
        className="absolute top-[40%] left-[44%] w-[3%] h-[3%] border border-emerald-500/60 rounded-full z-20"
      />
       <motion.div 
        animate={{ 
          x: [0, 3, -2, 1, 0],
          y: [0, -2, 2, -1, 0],
        }}
        transition={{ duration: 5, repeat: Infinity, ease: "easeInOut", delay: 0.1 }}
        className="absolute top-[40%] left-[53%] w-[3%] h-[3%] border border-emerald-500/60 rounded-full z-20"
      />

      <div className="absolute inset-0 flex items-center justify-center pointer-events-none opacity-40">
        <Target className="w-12 h-12 text-blue-500/30" />
      </div>

      <div className="absolute bottom-6 left-6 right-6 z-20 flex justify-between items-end">
        <div className="space-y-1">
          <p className="text-[10px] font-mono text-neutral-500 uppercase">Detection Mode</p>
          <p className="text-xs font-bold text-neutral-100 uppercase tracking-wider">Passive Surveillance</p>
        </div>
        <div className="bg-blue-500/10 border border-blue-500/30 px-4 py-2 rounded-xl backdrop-blur-md">
          <div className="flex items-center gap-3">
             <Scan className="w-4 h-4 text-blue-400 animate-pulse" />
             <span className="text-xs font-bold text-blue-400 uppercase tracking-[0.1em]">AI Engine Ver. 2.4.0</span>
          </div>
        </div>
      </div>
    </div>
  );
}
