"use client";

import { useState, useEffect } from "react";
import { 
  Shield, 
  Car, 
  MapPin, 
  AlertTriangle, 
  Radio, 
  Battery, 
  Wifi,
  ArrowUp,
  ArrowDown,
  ArrowLeft,
  ArrowRight,
  Octagon
} from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import dynamic from "next/dynamic";

const Map = dynamic(() => import("@/components/Map"), { 
  ssr: false,
  loading: () => <div className="w-full h-64 bg-neutral-900 animate-pulse rounded-2xl border border-neutral-800 flex items-center justify-center text-neutral-500">Loading Map...</div>
});

const VisionFeed = dynamic(() => import("@/components/VisionFeed"), { 
  ssr: false,
  loading: () => <div className="w-full h-64 bg-neutral-900 animate-pulse rounded-3xl border border-neutral-800 flex items-center justify-center text-neutral-500">Initializing VisionGuard AI...</div>
});

export default function Dashboard() {
  const [activeAlert, setActiveAlert] = useState<string | null>(null);
  const [logs, setLogs] = useState([
    { id: 1, type: "system", msg: "Dashboard initialized. Ready for link.", time: "10:00:00 AM" }
  ]);
  const [espIP, setEspIP] = useState("10.46.201.95"); 
  const [isConnected, setIsConnected] = useState(false);
  const [isPinging, setIsPinging] = useState(false);
  const [location, setLocation] = useState({ lat: 40.7128, lng: -74.0060 });

  // Connection Heartbeat
  useEffect(() => {
    const checkConnection = async () => {
      if (!espIP) return;
      setIsPinging(true);
      try {
        const res = await fetch(`/api/proxy`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ cmd: "ping", ip: espIP }) // A simple root check
        });
        const data = await res.json();
        setIsConnected(data.success);
      } catch (e) {
        setIsConnected(false);
      } finally {
        setIsPinging(false);
      }
    };

    checkConnection(); // Initial check
    const interval = setInterval(checkConnection, 10000); // Check every 10s
    return () => clearInterval(interval);
  }, [espIP]);

  // Poll for real-time alerts from the Vision Model
  useEffect(() => {
    const timer = setInterval(async () => {
      try {
        const res = await fetch("/api/alerts");
        const data = await res.json();
        if (data && data.alert) {
          let alertMsg = "";
          if (data.alert.type === "drowsiness") alertMsg = "DROWSINESS DETECTED - SEVERE";
          else if (data.alert.type === "distraction") alertMsg = "DRIVER DISTRACTED - WARNING";
          else if (data.alert.type === "crash") alertMsg = "CRITICAL COLLISION DETECTED - SMS SENT";
          
          if (alertMsg) triggerAlert(alertMsg);
        }
      } catch (err) {
        // Silent fail on polling errors
      }
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const triggerAlert = (msg: string) => {
    setActiveAlert(msg);
    addLog("alert", msg);
    setTimeout(() => setActiveAlert(null), 8000);
  };

  const addLog = (type: string, msg: string) => {
    setLogs(prev => [{
      id: Date.now(),
      type,
      msg,
      time: new Date().toLocaleTimeString()
    }, ...prev].slice(0, 10)); // keep last 10
  };

  const handleControlCommand = async (cmd: string) => {
    addLog("command", `Sending RC Command: ${cmd.toUpperCase()}`);
    try {
      if (espIP) {
        // Send the request to our Next.js backend proxy, bypassing browser restrictions!
        const res = await fetch(`/api/proxy`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ cmd, ip: espIP })
        });
        
        const data = await res.json();
        if (!data.success) {
           addLog("error", "ESP32 timeout or unreachable.");
        }
      } else {
        addLog("error", "ESP32 IP is not configured.");
      }
    } catch (e) {
      addLog("error", "Dashboard proxy failed.");
    }
  };

  return (
    <div className="min-h-screen bg-neutral-950 text-neutral-100 font-sans p-6 selection:bg-blue-500/30">
      {/* Header */}
      <header className="flex items-center justify-between mb-8 pb-6 border-b border-neutral-800">
        <div className="flex items-center gap-4">
          <div className="bg-gradient-to-br from-blue-600 to-purple-600 p-3 rounded-2xl shadow-lg shadow-blue-500/20">
            <Shield className="w-6 h-6 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold tracking-tight">VisionGuard Override</h1>
            <p className="text-sm text-neutral-400 font-medium">Monitoring Unit: VG-001</p>
          </div>
        </div>

        <div className="flex items-center gap-6 bg-neutral-900/50 backdrop-blur-md px-6 py-3 rounded-2xl border border-neutral-800/50">
          <div className="flex items-center gap-2">
            <Wifi className={`w-4 h-4 ${isConnected ? "text-emerald-400" : "text-red-500"} ${isPinging ? "animate-pulse" : ""}`} />
            <span className={`text-sm font-medium ${isConnected ? "text-neutral-300" : "text-red-400"}`}>
              {isConnected ? "Connected to ESP32" : "Searching for ESP32..."}
            </span>
          </div>
          <div className="w-px h-6 bg-neutral-800" />
          <div className="flex items-center gap-2">
            <Battery className="w-4 h-4 text-yellow-500" />
            <span className="text-sm text-neutral-300 font-medium">84%</span>
          </div>
          <div className="w-px h-6 bg-neutral-800" />
          <div className="flex items-center gap-2">
            <Car className="w-4 h-4 text-blue-400" />
            <span className="text-sm text-neutral-300 font-medium">Active</span>
          </div>
        </div>
      </header>

      {/* Main Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Left Column: Alerts & Telemetry */}
        <div className="lg:col-span-2 space-y-6">
          
          {/* Active Alert Banner */}
          <AnimatePresence>
            {activeAlert && (
              <motion.div
                initial={{ opacity: 0, height: 0, y: -20 }}
                animate={{ opacity: 1, height: "auto", y: 0 }}
                exit={{ opacity: 0, height: 0, y: -20 }}
                className="bg-red-500/10 border border-red-500/50 rounded-2xl p-6 relative overflow-hidden flex items-center gap-4 shadow-[0_0_30px_rgba(239,68,68,0.2)]"
              >
                <div className="absolute inset-0 bg-red-500/5 animate-pulse" />
                <AlertTriangle className="w-8 h-8 text-red-500 relative z-10 shrink-0" />
                <div className="relative z-10 w-full">
                  <h3 className="text-red-400 font-bold text-lg mb-1">EMERGENCY OVERRIDE REQUIRED</h3>
                  <p className="text-red-200">{activeAlert}</p>
                </div>
                <button 
                  onClick={() => {
                    handleControlCommand("stop");
                    setActiveAlert(null);
                  }}
                  className="relative z-10 shrink-0 bg-red-500 hover:bg-red-600 text-white px-6 py-3 rounded-xl font-bold transition-all shadow-lg active:scale-95 whitespace-nowrap"
                >
                  HALT VEHICLE
                </button>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Telemetry Cards */}
          <div className="grid grid-cols-2 gap-6">
            <div className="bg-neutral-900 border border-neutral-800 rounded-3xl p-6 flex flex-col">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-3">
                  <MapPin className="text-purple-400 w-5 h-5" />
                  <h3 className="text-neutral-300 font-semibold">Live Location</h3>
                </div>
                <div className="flex gap-4 text-[10px] font-mono text-neutral-500 uppercase tracking-wider">
                  <span>Lat: {location.lat.toFixed(4)}</span>
                  <span>Lng: {location.lng.toFixed(4)}</span>
                </div>
              </div>
              <div className="flex-1 min-h-[300px]">
                <Map lat={location.lat} lng={location.lng} />
              </div>
            </div>

            <div className="bg-neutral-900 border border-neutral-800 rounded-3xl p-6">
              <div className="flex items-center gap-3 mb-4">
                <Radio className="text-blue-400 w-5 h-5" />
                <h3 className="text-neutral-300 font-semibold">Last SMS Status</h3>
              </div>
              <div className="h-full flex flex-col justify-center gap-4 pb-4">
                 <div className="flex items-center gap-3 bg-neutral-950 p-4 rounded-xl border border-neutral-800/50">
                    <div className={`w-3 h-3 rounded-full ${activeAlert?.includes("CRITICAL") ? "bg-red-500 animate-ping" : "bg-emerald-500"} shadow-lg`}></div>
                    <div>
                      <p className={`text-sm font-medium ${activeAlert?.includes("CRITICAL") ? "text-red-400" : "text-emerald-400"}`}>
                        {activeAlert?.includes("CRITICAL") ? "SMS ALERT SENT" : "Twilio Cloud Ready"}
                      </p>
                      <p className="text-xs text-neutral-500">Target: +918114547691</p>
                    </div>
                 </div>
              </div>
            </div>
          </div>

          {/* Video / Vision Feed Placeholder */}
          <div className="aspect-video relative">
             <VisionFeed />
          </div>
          
        </div>

        {/* Right Column: Controls & Logs */}
        <div className="space-y-6">
          
          {/* RC Control Pad */}
          <div className="bg-neutral-900 border border-neutral-800 rounded-3xl p-6">
            <h3 className="text-neutral-300 font-semibold mb-6 flex items-center gap-2">
               Hardware Override
            </h3>
            
            <div className="grid grid-cols-3 gap-3 w-max mx-auto mb-6">
              <div /> {/* Empty top-left */}
              <button 
                onMouseDown={() => handleControlCommand("forward")}
                onMouseUp={() => handleControlCommand("stop")}
                className="w-16 h-16 bg-neutral-800 hover:bg-neutral-700 active:bg-blue-600 rounded-2xl flex items-center justify-center transition-colors shadow-inner"
              >
                <ArrowUp className="w-6 h-6" />
              </button>
              <div /> {/* Empty top-right */}
              
              <button 
                onMouseDown={() => handleControlCommand("left")}
                onMouseUp={() => handleControlCommand("stop")}
                className="w-16 h-16 bg-neutral-800 hover:bg-neutral-700 active:bg-blue-600 rounded-2xl flex items-center justify-center transition-colors shadow-inner"
              >
                <ArrowLeft className="w-6 h-6" />
              </button>
              <button 
                onClick={() => handleControlCommand("stop")}
                className="w-16 h-16 bg-red-500/20 hover:bg-red-500 text-red-500 hover:text-white border border-red-500/50 active:bg-red-600 rounded-2xl flex items-center justify-center transition-colors"
               >
                <Octagon className="w-6 h-6" />
              </button>
              <button 
                onMouseDown={() => handleControlCommand("right")}
                onMouseUp={() => handleControlCommand("stop")}
                className="w-16 h-16 bg-neutral-800 hover:bg-neutral-700 active:bg-blue-600 rounded-2xl flex items-center justify-center transition-colors shadow-inner"
              >
                <ArrowRight className="w-6 h-6" />
              </button>

              <div />
              <button 
                onMouseDown={() => handleControlCommand("backward")}
                onMouseUp={() => handleControlCommand("stop")}
                className="w-16 h-16 bg-neutral-800 hover:bg-neutral-700 active:bg-blue-600 rounded-2xl flex items-center justify-center transition-colors shadow-inner"
              >
                <ArrowDown className="w-6 h-6" />
              </button>
              <div />
            </div>

            <div className="mt-4 flex flex-col gap-2">
              <label className="text-xs text-neutral-500 mb-1 block">ESP32 Manual IP Routing</label>
              <div className="flex gap-2">
                <input 
                  type="text" 
                  value={espIP}
                  onChange={(e) => setEspIP(e.target.value)}
                  placeholder="e.g. 192.168.1.5"
                  className={`flex-1 bg-neutral-950 border rounded-xl px-4 py-2 text-sm text-neutral-300 focus:outline-none ${isConnected ? "border-emerald-500/30" : "border-neutral-800 focus:border-blue-500/50"}`}
                />
                <button 
                  onClick={() => handleControlCommand("ping")}
                  className="bg-neutral-800 hover:bg-neutral-700 text-neutral-300 px-3 py-2 rounded-xl text-xs font-bold transition-all"
                >
                  RESCAN
                </button>
              </div>
              {!isConnected && (
                <div className="mt-2 p-3 bg-red-500/10 border border-red-500/20 rounded-lg">
                  <p className="text-[10px] text-red-400 font-mono leading-tight">
                    * ESP32 at {espIP} is unreachable.<br/>
                    1. Check Serial Monitor for actual IP.<br/>
                    2. Ensure Phone Hotspot SSID is "NINJA".<br/>
                    3. Ensure Laptop + ESP are on same network.
                  </p>
                </div>
              )}
            </div>
          </div>

          {/* System Logs */}
          <div className="bg-neutral-900 border border-neutral-800 rounded-3xl p-6 flex flex-col h-[400px]">
            <h3 className="text-neutral-300 font-semibold mb-4 border-b border-neutral-800 pb-4">
              System Console
            </h3>
            <div className="flex-1 overflow-y-auto space-y-3 font-mono text-xs pr-2 custom-scrollbar">
              <AnimatePresence>
                {logs.map((log) => (
                  <motion.div 
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    key={log.id} 
                    className={`p-3 rounded-lg border ${
                      log.type === 'alert' ? 'bg-red-500/10 border-red-500/30 text-red-400' :
                      log.type === 'command' ? 'bg-blue-500/10 border-blue-500/30 text-blue-400' :
                      'bg-neutral-950 border-neutral-800 text-neutral-400'
                    }`}
                  >
                    <span className="opacity-50 mr-2">[{log.time}]</span>
                    {log.msg}
                  </motion.div>
                ))}
              </AnimatePresence>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}
