# Nightcap Waitlist — Setup Guide

## Quick Start (Local Preview)

Open `preview.html` in a browser. The full flow works locally with mock data.

---

## Shopify Deployment

### 1. Theme Files
Upload to your Shopify theme:
```
layout/theme.liquid
templates/page.waitlist.liquid
sections/nightcap-hero.liquid
sections/nightcap-why.liquid
sections/nightcap-how.liquid
sections/nightcap-ingredients.liquid
sections/nightcap-proof.liquid
sections/nightcap-faq.liquid
sections/nightcap-calculating.liquid
sections/nightcap-sugar-quiz.liquid
sections/nightcap-waitlist-signup.liquid
sections/nightcap-results.liquid
sections/nightcap-footer.liquid
assets/nightcap-landing.css
assets/nightcap-ab.js
assets/nightcap-quiz.js
assets/nightcap-waitlist.js
config/settings_schema.json
```

### 2. Create a Page
In Shopify Admin → Pages → Add Page:
- Title: "Waitlist" (or anything)
- Template: `page.waitlist`

---

## Backend (API Endpoints)

Deploy `api/waitlist-subscribe.js` and `api/waitlist-sms.js` as serverless functions.

**Options:**
- **Vercel**: Drop files in `/api/` folder, deploy
- **Netlify**: Use as Netlify Functions
- **Cloudflare Workers**: Wrap in Worker format
- **Shopify App Proxy**: Route through your Shopify app

### Environment Variables

| Variable | Service | Description |
|---|---|---|
| `KLAVIYO_PRIVATE_KEY` | Klaviyo | Private API key |
| `KLAVIYO_WAITLIST_LIST_ID` | Klaviyo | List ID for waitlist subscribers |
| `TWILIO_ACCOUNT_SID` | Twilio | Account SID |
| `TWILIO_AUTH_TOKEN` | Twilio | Auth token |
| `TWILIO_PHONE_NUMBER` | Twilio | Your Twilio phone number |
| `APP_DOWNLOAD_URL` | — | Your app's download URL |

---

## Klaviyo Setup

### 1. Create a List
- Name: "Nightcap Waitlist"
- Note the List ID for `KLAVIYO_WAITLIST_LIST_ID`

### 2. Create a Flow
- **Trigger**: Metric → "Joined Waitlist"
- **Email 1** (Immediate): Use `email-templates/waitlist-welcome.html`
  - Subject: `{{ first_name }}, your sugar report is in ☕`
  - Preview text: `You're consuming {{ quiz_estimated_daily_sugar }}g of sugar per day from drinks.`
- **Email 2** (Day 3): "Meet the ingredients in Nightcap"
- **Email 3** (Day 7): "You're #{{ waitlist_position }} — refer friends to skip the line"

### 3. Quiz Data as Profile Properties
The API automatically stores these on each Klaviyo profile:
- `quiz_evening_drink`
- `quiz_daily_sugary_drinks`
- `quiz_sleep_quality`
- `quiz_motivation`
- `quiz_checks_sugar`
- `quiz_estimated_daily_sugar`
- `quiz_estimated_weekly_sugar`
- `quiz_estimated_yearly_sugar_lbs`

Use these for **segmentation**:
- "Heavy sugar users" → `quiz_estimated_daily_sugar > 50`
- "Sleep-focused" → `quiz_motivation == "sleep_better"`
- "Sugar-unaware" → `quiz_checks_sugar == "never"`

---

## Twilio SMS Setup

1. Create a Twilio account
2. Get a phone number (US)
3. Set environment variables
4. The SMS sends a personalized message based on quiz motivation + sugar data
5. Message includes the app download link

**SMS Compliance:**
- STOP/unsubscribe handling is built into Twilio
- Consent checkbox is required before sending
- Legal disclaimer included in signup form

---

## Analytics

The quiz fires events to:
- **Google Tag Manager**: `window.dataLayer.push()` with `nightcap_*` events
- **Facebook Pixel**: `fbq('trackCustom', ...)` if pixel is loaded
- **Custom Events**: `window.dispatchEvent(new CustomEvent('nightcap:*'))`

### Events Tracked
| Event | When |
|---|---|
| `quiz_started` | User clicks "Take the Sugar Quiz" |
| `quiz_answer` | Each question answered (includes question + answer) |
| `quiz_completed` | All 5 questions done |
| `waitlist_signup` | Form submitted successfully |
| `referral_copied` | Referral link copied |
| `referral_shared` | Shared via Twitter/SMS/email |
| `app_download_clicked` | Download app button clicked |

---

## Referral System

- Unique code generated from email hash (e.g., `NC3F8A2K`)
- Referral URL: `yoursite.com/pages/waitlist?ref=NC3F8A2K`
- UTM params are captured and included in the signup payload
- To track referrals server-side, match `ref` param to existing subscribers

---

## Customization

### Change Launch Date
In `assets/nightcap-waitlist.js`, update:
```js
launchDate: new Date('2026-07-15T09:00:00-04:00'),
```

### Change Colors
In `assets/nightcap-landing.css`, update CSS variables:
```css
--nc-primary: #7c3aed;      /* Main purple */
--nc-accent: #06d6a0;       /* Green accent */
```

### Change Waitlist Count
In hero section settings or directly in HTML:
```html
<strong id="waitlist-count">2,847</strong>
```
