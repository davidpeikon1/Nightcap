/**
 * Nightcap Waitlist Subscribe API
 *
 * Serverless endpoint that handles waitlist signups.
 * Deploy as a Shopify App Proxy, Vercel function, or Cloudflare Worker.
 *
 * Receives: { first_name, email, phone, sms_consent, email_consent, quiz_data, source }
 * Stores subscriber data and triggers email/SMS flows.
 *
 * Integration options:
 * - Klaviyo (recommended for Shopify): Create profile + add to list + trigger flow
 * - Twilio / Postscript: SMS delivery
 * - SendGrid / Mailgun: Email delivery
 */

// ---- Configuration (set via environment variables) ----
const KLAVIYO_API_KEY = process.env.KLAVIYO_PRIVATE_KEY || '';
const KLAVIYO_LIST_ID = process.env.KLAVIYO_WAITLIST_LIST_ID || '';
const TWILIO_ACCOUNT_SID = process.env.TWILIO_ACCOUNT_SID || '';
const TWILIO_AUTH_TOKEN = process.env.TWILIO_AUTH_TOKEN || '';
const TWILIO_PHONE_NUMBER = process.env.TWILIO_PHONE_NUMBER || '';
const APP_DOWNLOAD_URL = process.env.APP_DOWNLOAD_URL || 'https://nightcap.app/download';

/**
 * Main handler — works with Vercel, Netlify, or Express
 */
module.exports = async function handler(req, res) {
  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;

    const {
      first_name,
      email,
      phone,
      sms_consent,
      email_consent,
      quiz_data,
      source,
    } = body;

    // Basic validation
    if (!email || !first_name) {
      return res.status(400).json({ error: 'Name and email are required' });
    }

    // 1. Add to Klaviyo (or your email platform)
    const klaviyoResult = await addToKlaviyo({
      first_name,
      email,
      phone,
      sms_consent,
      email_consent,
      quiz_data,
      source,
    });

    // 2. If SMS consent + phone, trigger personalized text
    if (sms_consent && phone) {
      await sendPersonalizedSMS({
        phone,
        first_name,
        quiz_data,
      });
    }

    // 3. Generate waitlist position (simple increment)
    const position = klaviyoResult.position || generatePosition();

    return res.status(200).json({
      success: true,
      position: position,
      message: 'Welcome to the Nightcap waitlist!',
    });
  } catch (error) {
    console.error('Waitlist signup error:', error);
    return res.status(500).json({ error: 'Something went wrong. Please try again.' });
  }
};

// ---- Klaviyo Integration ----
async function addToKlaviyo({ first_name, email, phone, sms_consent, email_consent, quiz_data, source }) {
  if (!KLAVIYO_API_KEY) {
    console.log('[DEV] Klaviyo not configured. Subscriber data:', { first_name, email, phone });
    return { position: generatePosition() };
  }

  // Create/update profile with quiz data as custom properties
  const profilePayload = {
    data: {
      type: 'profile',
      attributes: {
        email: email,
        first_name: first_name,
        phone_number: phone || undefined,
        properties: {
          // Quiz data stored as profile properties for segmentation
          waitlist_source: source,
          quiz_evening_drink: quiz_data.evening_drink,
          quiz_daily_sugary_drinks: quiz_data.daily_sugary_drinks,
          quiz_sleep_quality: quiz_data.sleep_quality,
          quiz_motivation: quiz_data.motivation,
          quiz_checks_sugar: quiz_data.checks_sugar,
          quiz_estimated_daily_sugar: quiz_data.estimated_daily_sugar,
          quiz_estimated_weekly_sugar: quiz_data.estimated_weekly_sugar,
          quiz_estimated_yearly_sugar_lbs: quiz_data.estimated_yearly_sugar_lbs,
          sms_consent: sms_consent,
          email_consent: email_consent,
          signup_date: new Date().toISOString(),
        },
      },
    },
  };

  const profileRes = await fetch('https://a.klaviyo.com/api/profiles/', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: 'Klaviyo-API-Key ' + KLAVIYO_API_KEY,
      revision: '2024-02-15',
    },
    body: JSON.stringify(profilePayload),
  });

  const profileData = await profileRes.json();
  const profileId = profileData.data?.id;

  // Add to waitlist list
  if (profileId && KLAVIYO_LIST_ID) {
    await fetch('https://a.klaviyo.com/api/lists/' + KLAVIYO_LIST_ID + '/relationships/profiles/', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Klaviyo-API-Key ' + KLAVIYO_API_KEY,
        revision: '2024-02-15',
      },
      body: JSON.stringify({
        data: [{ type: 'profile', id: profileId }],
      }),
    });
  }

  // Trigger personalized welcome flow event
  await fetch('https://a.klaviyo.com/api/events/', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: 'Klaviyo-API-Key ' + KLAVIYO_API_KEY,
      revision: '2024-02-15',
    },
    body: JSON.stringify({
      data: {
        type: 'event',
        attributes: {
          metric: { data: { type: 'metric', attributes: { name: 'Joined Waitlist' } } },
          profile: { data: { type: 'profile', attributes: { email: email } } },
          properties: {
            motivation: quiz_data.motivation,
            estimated_daily_sugar: quiz_data.estimated_daily_sugar,
            sleep_quality: quiz_data.sleep_quality,
            app_download_url: APP_DOWNLOAD_URL,
          },
        },
      },
    }),
  });

  return { position: generatePosition() };
}

// ---- SMS via Twilio ----
async function sendPersonalizedSMS({ phone, first_name, quiz_data }) {
  if (!TWILIO_ACCOUNT_SID) {
    console.log('[DEV] Twilio not configured. Would send SMS to:', phone);
    return;
  }

  const sugar = quiz_data.estimated_daily_sugar || 0;
  const motivation = quiz_data.motivation;

  const motivationLines = {
    cut_sugar: "You're consuming ~" + sugar + "g of sugar/day from drinks. Nightcap has 0g.",
    sleep_better: 'Nightcap is made with ingredients clinically shown to improve sleep.',
    healthier_habits: "One swap can change everything. You'd cut " + sugar + "g/day of sugar.",
    relaxation: 'Unwind without the sugar crash. Nightcap uses adaptogens, not sugar.',
  };

  const message =
    'Hey ' + first_name + '! ' +
    (motivationLines[motivation] || 'Thanks for joining the Nightcap waitlist!') +
    '\n\nDownload the app: ' + APP_DOWNLOAD_URL +
    '\n\nReply STOP to opt out.';

  const params = new URLSearchParams();
  params.append('To', phone);
  params.append('From', TWILIO_PHONE_NUMBER);
  params.append('Body', message);

  await fetch(
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
}

// ---- Helpers ----
function generatePosition() {
  // In production, query your DB for actual count
  return Math.floor(Math.random() * 500) + 2800;
}
