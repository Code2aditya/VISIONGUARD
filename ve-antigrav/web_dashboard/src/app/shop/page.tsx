"use client";

import { Shield, Cpu, Activity, Glasses, Battery, MapPin, Package, ArrowRight, CheckCircle2 } from "lucide-react";
import { motion } from "framer-motion";
import Link from 'next/link';

const features = [
  {
    title: "AI Driver Monitoring",
    description: "Advanced laptop-based vision models detect drowsiness and distraction in real-time, preventing accidents before they happen.",
    icon: <Glasses className="w-6 h-6 text-blue-400" />
  },
  {
    title: "ESP32 Hardware Core",
    description: "A robust microcontroller handles sensor telemetry, motor control, and WebSocket/HTTP communications with zero latency.",
    icon: <Cpu className="w-6 h-6 text-purple-400" />
  },
  {
    title: "Collision & SMS Alerts",
    description: "MPU6050 accelerometer detects sudden impacts, instantly triggering SIM800L to dispatch SMS alerts with GPS coordinates.",
    icon: <Activity className="w-6 h-6 text-red-400" />
  },
  {
    title: "Centralized Dashboard",
    description: "Monitor fleet health, view live AI alerts, and take manual RC control of the vehicle from any web browser.",
    icon: <Shield className="w-6 h-6 text-emerald-400" />
  }
];

export default function ShopPage() {
  return (
    <div className="min-h-screen bg-neutral-950 text-neutral-100 font-sans selection:bg-blue-500/30">
      
      {/* Navigation */}
      <nav className="fixed top-0 left-0 right-0 z-50 bg-neutral-950/80 backdrop-blur-md border-b border-neutral-800">
        <div className="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="bg-gradient-to-br from-blue-600 to-purple-600 p-2 rounded-xl">
              <Shield className="w-5 h-5 text-white" />
            </div>
            <span className="text-xl font-bold tracking-tight">VisionGuard</span>
          </div>
          <div className="flex items-center gap-4">
            <Link 
              href="/login" 
              className="text-sm font-medium text-neutral-400 hover:text-white transition-colors"
            >
              System Login
            </Link>
            <Link 
              href="#purchase" 
              className="bg-white text-black px-5 py-2 rounded-full text-sm font-bold hover:bg-neutral-200 transition-colors"
            >
              Get VisionGuard
            </Link>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="pt-40 pb-20 px-6 relative overflow-hidden">
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-blue-600/20 rounded-full blur-[120px] -z-10" />
        
        <div className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <motion.div 
            initial={{ opacity: 0, x: -30 }}
            animate={{ opacity: 1, x: 0 }}
            className="space-y-8"
          >
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-500/10 border border-blue-500/20 text-blue-400 text-sm font-medium">
              <span className="w-2 h-2 rounded-full bg-blue-500 animate-pulse" />
              Next-Gen Fleet Safety
            </div>
            <h1 className="text-5xl lg:text-7xl font-bold tracking-tighter leading-tight">
              Protect your drivers with <span className="bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">AI & edge computing.</span>
            </h1>
            <p className="text-xl text-neutral-400 leading-relaxed max-w-lg">
              The VisionGuard platform combines local AI driver monitoring with an ESP32 edge processing unit to prevent accidents and automate emergency responses.
            </p>
            <div className="flex items-center gap-4 pt-4">
              <Link 
                href="#purchase" 
                className="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-500 hover:to-purple-500 text-white px-8 py-4 rounded-full font-bold transition-all shadow-lg shadow-blue-500/25 flex items-center gap-2"
              >
                Order Developer Kit <ArrowRight className="w-5 h-5" />
              </Link>
            </div>
          </motion.div>

          {/* Hero Visual */}
          <motion.div 
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="relative"
          >
            <div className="aspect-square rounded-full border border-neutral-800 absolute -inset-10 animate-[spin_60s_linear_infinite]" />
            <div className="aspect-square rounded-full border border-neutral-800/50 absolute -inset-20 animate-[spin_90s_linear_infinite_reverse]" />
            
            <div className="bg-neutral-900 border border-neutral-800 rounded-3xl p-8 relative z-10 shadow-2xl">
              <div className="grid grid-cols-2 gap-4 mb-4">
                <div className="bg-neutral-950 p-4 rounded-2xl border border-neutral-800/50 flex flex-col gap-2">
                  <MapPin className="w-6 h-6 text-emerald-400" />
                  <span className="text-sm text-neutral-400 font-medium">Live GPS Tracking</span>
                </div>
                <div className="bg-neutral-950 p-4 rounded-2xl border border-neutral-800/50 flex flex-col gap-2">
                  <Battery className="w-6 h-6 text-yellow-400" />
                  <span className="text-sm text-neutral-400 font-medium">9V/12V L298N Power</span>
                </div>
              </div>
              <div className="bg-neutral-950 rounded-2xl border border-neutral-800/50 aspect-video flex items-center justify-center p-6 text-center">
                 <div>
                    <Cpu className="w-12 h-12 text-blue-500 mx-auto mb-3" />
                    <p className="font-mono text-xs text-neutral-500">ESP32 CORE ACTIVE • MPU6050 SYNCED</p>
                 </div>
              </div>
            </div>
          </motion.div>
        </div>
      </section>

      {/* How it Works */}
      <section className="py-24 bg-neutral-900/50 border-y border-neutral-800">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center max-w-2xl mx-auto mb-16">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">How VisionGuard Works</h2>
            <p className="text-neutral-400 text-lg">A seamless integration between software AI and hardware telemetry.</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {features.map((feature, i) => (
              <div key={i} className="bg-neutral-900 border border-neutral-800 p-8 rounded-3xl hover:border-blue-500/50 transition-colors group">
                <div className="bg-neutral-950 w-14 h-14 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform border border-neutral-800">
                  {feature.icon}
                </div>
                <h3 className="text-xl font-bold mb-3">{feature.title}</h3>
                <p className="text-neutral-400 leading-relaxed text-sm">
                  {feature.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing / Purchase */}
      <section id="purchase" className="py-24">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <h2 className="text-3xl md:text-4xl font-bold mb-4">Get the Developer Kit</h2>
          <p className="text-neutral-400 text-lg mb-12">Everything you need to build and deploy the VisionGuard RC Prototype.</p>
          
          <div className="bg-gradient-to-b from-neutral-900 to-neutral-950 border border-neutral-800 rounded-3xl p-10 md:p-14 relative overflow-hidden text-left">
            <div className="absolute top-0 right-0 w-64 h-64 bg-purple-500/10 rounded-full blur-[80px]" />
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-center relative z-10">
              <div>
                <h3 className="text-2xl font-bold mb-2">Complete Hardware Bundle</h3>
                <div className="text-4xl font-bold mb-6">$89<span className="text-xl text-neutral-500 font-normal">.99</span></div>
                
                <ul className="space-y-4 mb-8">
                  {['ESP32 NodeMCU Board', 'MPU6050 Accelerometer/Gyro', 'NEO-6M GPS Module with Antenna', 'SIM800L GSM Module', 'L298N Motor Driver & Chassis base', 'Python & Next.js Source Code Access'].map((item, i) => (
                    <li key={i} className="flex items-start gap-3">
                      <CheckCircle2 className="w-5 h-5 text-blue-400 shrink-0 mt-0.5" />
                      <span className="text-neutral-300">{item}</span>
                    </li>
                  ))}
                </ul>
                
                <button className="w-full bg-white text-black font-bold py-4 rounded-xl hover:bg-neutral-200 transition-colors flex items-center justify-center gap-2">
                  <Package className="w-5 h-5" /> Proceed to Checkout
                </button>
              </div>
              
              <div className="bg-neutral-950 p-8 rounded-2xl border border-neutral-800 items-center justify-center flex flex-col text-center">
                 <Shield className="w-16 h-16 text-neutral-800 mb-4" />
                 <p className="text-neutral-500 font-medium">Pre-flashed firmware available upon request.</p>
                 <Link href="/login" className="mt-6 text-blue-400 hover:text-blue-300 text-sm font-medium">
                   Already have a kit? Login to Dashboard &rarr;
                 </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-neutral-900 py-12 text-center text-neutral-600 text-sm">
        <p>© 2026 VisionGuard Systems. All rights reserved.</p>
      </footer>
    </div>
  );
}
