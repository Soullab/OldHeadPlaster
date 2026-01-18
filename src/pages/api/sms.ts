import type { APIRoute } from 'astro';

export const prerender = false;

export const POST: APIRoute = async ({ request }) => {
  try {
    const { to, message } = await request.json();

    if (!to || !message) {
      return new Response(
        JSON.stringify({ success: false, error: 'Phone number and message are required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Get Twilio credentials from environment
    const accountSid = import.meta.env.TWILIO_ACCOUNT_SID;
    const authToken = import.meta.env.TWILIO_AUTH_TOKEN;
    const fromPhone = import.meta.env.TWILIO_PHONE_NUMBER;

    if (!accountSid || !authToken || !fromPhone) {
      console.log('Twilio not configured, using fallback');
      // Return success but indicate SMS was not actually sent
      // The frontend will fall back to opening native SMS app
      return new Response(
        JSON.stringify({
          success: false,
          error: 'SMS service not configured',
          fallback: true
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Format phone number (remove non-digits, add +1 if needed)
    let formattedPhone = to.replace(/\D/g, '');
    if (formattedPhone.length === 10) {
      formattedPhone = '1' + formattedPhone;
    }
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+' + formattedPhone;
    }

    // Send via Twilio REST API
    const twilioUrl = `https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`;

    const response = await fetch(twilioUrl, {
      method: 'POST',
      headers: {
        'Authorization': 'Basic ' + btoa(`${accountSid}:${authToken}`),
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: new URLSearchParams({
        To: formattedPhone,
        From: fromPhone,
        Body: message
      })
    });

    const result = await response.json();

    if (response.ok) {
      return new Response(
        JSON.stringify({ success: true, sid: result.sid }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    } else {
      console.error('Twilio error:', result);
      return new Response(
        JSON.stringify({ success: false, error: result.message || 'Failed to send SMS' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    }

  } catch (error) {
    console.error('SMS API error:', error);
    return new Response(
      JSON.stringify({ success: false, error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
};
