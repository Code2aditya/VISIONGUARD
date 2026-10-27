import { NextResponse } from 'next/server';

// WhatsApp notification handler supporting CircuitDigest Cloud (Primary) and Twilio (Fallback)
const CIRCUITDIGEST_API_KEY = process.env.CIRCUITDIGEST_API_KEY;
const TWILIO_ACCOUNT_SID = process.env.TWILIO_ACCOUNT_SID;
const TWILIO_AUTH_TOKEN = process.env.TWILIO_AUTH_TOKEN;
const TWILIO_WHATSAPP_FROM = process.env.TWILIO_WHATSAPP_FROM || process.env.TWILIO_FROM_NUMBER;
const EMERGENCY_TARGET_NUMBER = process.env.EMERGENCY_TARGET_NUMBER || '+918114547691';

function toWhatsAppAddr(num: string | undefined): string {
  const n = (num || '').trim();
  if (!n) return '';
  if (n.toLowerCase().startsWith('whatsapp:')) return n;
  return `whatsapp:${n}`;
}

export async function POST(req: Request) {
  try {
    const { type, location } = await req.json();

    console.log(`[Emergency] Received ${type} alert at ${location}`);

    const mapUrl = location ? `https://maps.google.com/?q=${location}` : 'Unknown Location';
    let alertSent = false;
    let providerDetails: any = null;

    // 1. Primary: CircuitDigest Cloud WhatsApp API
    if (CIRCUITDIGEST_API_KEY) {
      try {
        const cleanPhone = EMERGENCY_TARGET_NUMBER.replace(/[^0-9]/g, '');
        console.log(`[Emergency] Dispatching WhatsApp via CircuitDigest to ${cleanPhone}...`);

        const cdRes = await fetch('https://www.circuitdigest.cloud/api/v1/whatsapp/send', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': CIRCUITDIGEST_API_KEY,
          },
          body: JSON.stringify({
            phone_number: cleanPhone,
            template_id: 'threshold_violation_alert',
            variables: {
              device_name: 'VisionGuard Cart',
              parameter: 'Accident / Impact',
              measured_value: `${type || 'Collision'} Detected`,
              limit: '15 m/s²',
              location: mapUrl,
            },
          }),
        });

        const cdData = await cdRes.json();
        console.log('[Emergency] CircuitDigest response:', cdData);

        if (cdRes.ok && (cdData.success || cdData.message_id)) {
          alertSent = true;
          providerDetails = { provider: 'circuitdigest', messageId: cdData.message_id };
        }
      } catch (cdErr) {
        console.error('[Emergency] CircuitDigest WhatsApp error:', cdErr);
      }
    }

    // 2. Fallback: Twilio WhatsApp API
    if (!alertSent && TWILIO_ACCOUNT_SID && TWILIO_AUTH_TOKEN) {
      try {
        const message = `VisionGuard CRITICAL ALERT! Type: ${type}. Location: ${location || 'Unknown'}. Maps: ${mapUrl} Immediate action required.`;
        const twilioUrl = `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`;
        const auth = Buffer.from(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`).toString('base64');

        const twilioRes = await fetch(twilioUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Authorization': `Basic ${auth}`,
          },
          body: new URLSearchParams({
            From: toWhatsAppAddr(TWILIO_WHATSAPP_FROM),
            To: toWhatsAppAddr(EMERGENCY_TARGET_NUMBER),
            Body: message,
          }),
        });

        const twilioData = await twilioRes.json();
        if (twilioRes.ok) {
          alertSent = true;
          providerDetails = { provider: 'twilio', messageId: twilioData.sid };
        } else {
          console.error('[Emergency] Twilio WhatsApp error:', twilioData);
        }
      } catch (twErr) {
        console.error('[Emergency] Twilio error:', twErr);
      }
    }

    // ALWAYS update the dashboard API so the Web Dashboard and Flutter Mobile App receive the alert & coordinates
    try {
      const baseUrl = req.url.split('/api/')[0];
      await fetch(`${baseUrl}/api/alerts`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          token: process.env.DASHBOARD_API_TOKEN || 'secret_token_123',
          type: 'crash',
          severity: 'CRITICAL',
          location: location || '28.7041, 77.1025',
          timestamp: new Date().toISOString(),
        }),
      });
      console.log('[Emergency] Successfully synced crash alert & coordinates to dashboard API.');
    } catch (e) {
      console.error('[Emergency] Failed to update dashboard UI:', e);
    }

    return NextResponse.json({
      success: true,
      alertSent,
      ...providerDetails,
      channel: 'whatsapp',
      location: location || '28.7041, 77.1025',
    });
  } catch (err: any) {
    console.error('[API Error]', err);
    return NextResponse.json({ success: false, error: err.message }, { status: 500 });
  }
}

