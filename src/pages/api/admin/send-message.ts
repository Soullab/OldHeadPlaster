import type { APIRoute } from 'astro';

export const prerender = false;

interface Recipient {
  name: string;
  email?: string;
  phone?: string;
  channel: 'email' | 'sms' | 'both';
}

interface MessageRequest {
  project: string;
  recipients: Recipient[];
  subject: string;
  message: string;
  channel: 'preferred' | 'email' | 'sms' | 'both';
  attachments?: string[];
}

async function sendEmail(to: string, subject: string, body: string) {
  const resendApiKey = import.meta.env.RESEND_API_KEY;

  if (!resendApiKey) {
    console.log('Resend not configured, skipping email');
    return { success: false, error: 'Email service not configured' };
  }

  try {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        from: 'Daragh <daragh@oldheadplaster.com>',
        to: [to],
        subject: subject,
        text: body,
        html: `<div style="font-family: Georgia, serif; color: #333; max-width: 600px; margin: 0 auto;">
          <p style="white-space: pre-wrap;">${body.replace(/\n/g, '<br>')}</p>
          <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;" />
          <p style="color: #666; font-size: 14px;">
            Old Head Plaster · Master Craftsman Plastering<br />
            Connecticut's Shoreline<br />
            <a href="https://oldheadplaster.com" style="color: #A8935C;">oldheadplaster.com</a>
          </p>
        </div>`
      })
    });

    const result = await response.json();

    if (response.ok) {
      return { success: true, id: result.id };
    } else {
      console.error('Resend error:', result);
      return { success: false, error: result.message || 'Failed to send email' };
    }
  } catch (error) {
    console.error('Email error:', error);
    return { success: false, error: 'Email service error' };
  }
}

async function sendSMS(to: string, message: string) {
  const accountSid = import.meta.env.TWILIO_ACCOUNT_SID;
  const authToken = import.meta.env.TWILIO_AUTH_TOKEN;
  const fromPhone = import.meta.env.TWILIO_PHONE_NUMBER;

  if (!accountSid || !authToken || !fromPhone) {
    console.log('Twilio not configured, skipping SMS');
    return { success: false, error: 'SMS service not configured' };
  }

  try {
    // Format phone number
    let formattedPhone = to.replace(/\D/g, '');
    if (formattedPhone.length === 10) {
      formattedPhone = '1' + formattedPhone;
    }
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+' + formattedPhone;
    }

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
      return { success: true, sid: result.sid };
    } else {
      console.error('Twilio error:', result);
      return { success: false, error: result.message || 'Failed to send SMS' };
    }
  } catch (error) {
    console.error('SMS error:', error);
    return { success: false, error: 'SMS service error' };
  }
}

export const POST: APIRoute = async ({ request }) => {
  try {
    const data: MessageRequest = await request.json();

    if (!data.recipients || data.recipients.length === 0) {
      return new Response(
        JSON.stringify({ success: false, error: 'No recipients specified' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    if (!data.subject || !data.message) {
      return new Response(
        JSON.stringify({ success: false, error: 'Subject and message are required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const results = {
      emails: { sent: 0, failed: 0, errors: [] as string[] },
      sms: { sent: 0, failed: 0, errors: [] as string[] }
    };

    for (const recipient of data.recipients) {
      // Determine which channels to use
      let sendEmail = false;
      let sendSms = false;

      if (data.channel === 'preferred') {
        // Use recipient's preferred channel
        sendEmail = recipient.channel === 'email' || recipient.channel === 'both';
        sendSms = recipient.channel === 'sms' || recipient.channel === 'both';
      } else if (data.channel === 'email') {
        sendEmail = true;
      } else if (data.channel === 'sms') {
        sendSms = true;
      } else if (data.channel === 'both') {
        sendEmail = true;
        sendSms = true;
      }

      // Send email if applicable
      if (sendEmail && recipient.email) {
        const emailResult = await sendEmail(recipient.email, data.subject, data.message);
        if (emailResult.success) {
          results.emails.sent++;
        } else {
          results.emails.failed++;
          results.emails.errors.push(`${recipient.name}: ${emailResult.error}`);
        }
      }

      // Send SMS if applicable
      if (sendSms && recipient.phone) {
        // For SMS, include project context and keep it brief
        const smsMessage = `[Old Head Plaster - ${data.project}]\n\n${data.subject}\n\n${data.message.substring(0, 140)}${data.message.length > 140 ? '...' : ''}`;
        const smsResult = await sendSMS(recipient.phone, smsMessage);
        if (smsResult.success) {
          results.sms.sent++;
        } else {
          results.sms.failed++;
          results.sms.errors.push(`${recipient.name}: ${smsResult.error}`);
        }
      }
    }

    // Log message to activity log (in production, save to database)
    console.log('Message sent:', {
      project: data.project,
      subject: data.subject,
      recipients: data.recipients.map(r => r.name),
      channel: data.channel,
      results
    });

    const totalSent = results.emails.sent + results.sms.sent;
    const totalFailed = results.emails.failed + results.sms.failed;

    return new Response(
      JSON.stringify({
        success: totalSent > 0,
        message: `Sent ${totalSent} message(s)${totalFailed > 0 ? `, ${totalFailed} failed` : ''}`,
        results
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Send message API error:', error);
    return new Response(
      JSON.stringify({ success: false, error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
};
