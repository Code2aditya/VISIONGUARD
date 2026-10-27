import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const data = await request.json();
    const { cmd, ip } = data;

    if (!cmd || !ip) {
      return NextResponse.json({ success: false, message: 'Missing command or IP' }, { status: 400 });
    }

    // Proxy the request from the Next.js backend (Node.js) instead of the browser (React)
    // This bypasses entirely all CORS and Mixed-Content (HTTPS -> HTTP) restrictions!
    const espUrl = `http://${ip}/control?cmd=${cmd}`;
    console.log(`[Proxy] Forwarding command '${cmd}' to ${espUrl}`);

    const response = await fetch(espUrl, { 
        method: 'GET',
        // Increased timeout to 10 seconds to account for slow local networks
        signal: AbortSignal.timeout(10000),
        headers: {
          'Accept': '*/*',
          'Connection': 'keep-alive'
        }
    });

    if (response.ok) {
       const text = await response.text();
       return NextResponse.json({ success: true, message: text });
    } else {
       console.log(`[Proxy Error] ESP32 returned status ${response.status}`);
       return NextResponse.json({ success: false, message: `ESP32 returned status ${response.status}` }, { status: response.status });
    }

  } catch (error: any) {
    console.error(`[Proxy Failed] Could not reach the ESP32:`, error.message);
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
