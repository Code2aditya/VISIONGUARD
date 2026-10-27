"use client";

import { MapContainer, TileLayer, Marker, Popup, useMap } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import L from "leaflet";
import { useEffect } from "react";

// Fix for default marker icons in Leaflet with Next.js
const DefaultIcon = L.icon({
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  iconRetinaUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  iconSize: [25, 41],
  iconAnchor: [12, 41],
});

L.Marker.prototype.options.icon = DefaultIcon;

interface MapProps {
  lat: number;
  lng: number;
  zoom?: number;
}

function ChangeView({ center, zoom }: { center: [number, number], zoom: number }) {
  const map = useMap();
  useEffect(() => {
    map.setView(center, zoom);
  }, [center, zoom, map]);
  return null;
}

export default function Map({ lat, lng, zoom = 13 }: MapProps) {
  const position: [number, number] = [lat, lng];

  return (
    <div className="w-full h-full min-h-[300px] rounded-2xl overflow-hidden shadow-lg border border-neutral-800">
      <MapContainer 
        center={position} 
        zoom={zoom} 
        scrollWheelZoom={false}
        className="w-full h-full z-0"
      >
        {/* Using a dark themed tile layer from Stadia Maps or CartoDB for a premium look */}
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>'
          url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
        />
        <ChangeView center={position} zoom={zoom} />
        <Marker position={position}>
          <Popup>
            <div className="text-neutral-900 font-sans">
              <p className="font-bold">VisionGuard Unit VG-001</p>
              <p className="text-xs">{lat.toFixed(4)}, {lng.toFixed(4)}</p>
            </div>
          </Popup>
        </Marker>
      </MapContainer>
    </div>
  );
}
