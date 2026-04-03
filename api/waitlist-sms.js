/**
 * Nightcap SMS Endpoint
 * Dedicated endpoint for sending personalized SMS messages with app download link.
 * Deploy alongside waitlist-subscribe.js as a serverless function.
 */

const TWILIO_ACCOUNT_SID = process.env.TWILIO_ACCOUNT_SID || '';
const TWILIO_AUTH_TOKEN = process.env.TWILIO_AUTH_TOKEN || '';
const TWILIO_PHONE_NUMBER = process.env.TWILIO_PHONE_NUMBER || '';

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  try {
    var body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    var { phone, first_name, message, app_download_url } = body;

    if (!phone || !message) {
      return res.status(400).json({ error: 'Phone and message are required' });
    }

    if (!TWILIO_ACCOUNT_SID) {
      console.log('[DEV] SMS not configured. Would send to:', phone, '| Message:', message);
      return res.status(200).json({ success: true, dev: true });
    }

    var params = new URLSearchParams();
    params.append('To', phone);
    params.append('From', TWILIO_PHONE_NUMBER);
    params.append('Body', message);

    var twilioRes = await fetch(
      'https://api.twilio.com/2010-04-01/Accounts/' + TWILIO_ACCOUNT_SID + '/Messages.json',
      {
        method: 'POST',
        headers: {
          Authorization: 'Basic ' + Buffer.from(TWILIO_ACCOUNT_SID + ':' + TWILIO_AUTH_TOKEN).toString('base64'),
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params.toString(),
      }
    );

    var result = await twilioRes.json();

    if (!twilioRes.ok) {
      console.error('Twilio error:', result);
      return res.status(500).json({ error: 'SMS delivery failed' });
    }

    return res.status(200).json({ success: true, sid: result.sid });
  } catch (error) {
    console.error('SMS endpoint error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};
