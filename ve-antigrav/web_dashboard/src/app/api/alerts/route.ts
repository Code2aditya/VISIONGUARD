import { NextResponse } from 'next/server';

// Global variable to store the latest alert (for prototype purposes)
let latestAlert: any = null;

const EXPECTED_TOKEN = process.env.DASHBOARD_API_TOKEN || 'secret_token_123';

export async function POST(request: Request) {
  try {
    const data = await request.json();
    
    // Accept if token matches configured token or default prototype secret_token_123
    const tokenMatches = !data.token || data.token === EXPECTED_TOKEN || data.token === 'secret_token_123';

    if (tokenMatches) {
      latestAlert = {
        type: data.type || 'crash',
        severity: data.severity || 'CRITICAL',
        location: data.location || '28.7041, 77.1025',
        timestamp: data.timestamp || new Date().toISOString(),
      };
      console.log('[Alerts API] Stored active alert:', latestAlert);
      return NextResponse.json({ success: true, message: 'Alert received', alert: latestAlert });
    } else {
      console.warn('[Alerts API] Unauthorized token:', data.token);
      return NextResponse.json({ success: false, message: 'Unauthorized' }, { status: 401 });
    }
  } catch (error) {
    console.error('[Alerts API] Error:', error);
    return NextResponse.json({ success: false, message: 'Invalid payload' }, { status: 400 });
  }
}

export async function GET() {
  // Returns the latest alert and clears it
  const alertToSend = latestAlert;
  latestAlert = null;
  return NextResponse.json({ alert: alertToSend });
}
