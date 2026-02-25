import type { APIRoute } from 'astro';

export const prerender = false;

export const POST: APIRoute = async ({ request }) => {
  try {
    const formData = await request.formData();

    const clientName = formData.get('clientName') as string;
    const clientEmail = formData.get('clientEmail') as string;
    const clientPhone = formData.get('clientPhone') as string;
    const projectName = formData.get('projectName') as string;
    const location = formData.get('location') as string;
    const finishType = formData.get('finishType') as string;
    const tier = formData.get('tier') as string;
    const totalSqFt = formData.get('totalSqFt') as string;
    const lowEstimate = formData.get('lowEstimate') as string;
    const highEstimate = formData.get('highEstimate') as string;
    const quoteNumber = formData.get('quoteNumber') as string;
    const pdfFile = formData.get('pdf') as File | null;

    if (!clientEmail) {
      return new Response(
        JSON.stringify({ success: false, error: 'Client email is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    if (!clientName) {
      return new Response(
        JSON.stringify({ success: false, error: 'Client name is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const resendApiKey = process.env.RESEND_API_KEY;
    if (!resendApiKey) {
      return new Response(
        JSON.stringify({ success: false, error: 'Email service not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const estimateRange = `$${Number(lowEstimate).toLocaleString()} – $${Number(highEstimate).toLocaleString()}`;
    const projectLine = projectName ? `\nProject: ${projectName}` : '';

    const emailHtml = `
      <div style="font-family: Georgia, serif; color: #333; max-width: 600px; margin: 0 auto;">
        <div style="background: #2C2C2C; padding: 30px 40px; text-align: center;">
          <h1 style="color: #FAFAF8; font-size: 24px; letter-spacing: 2px; margin: 0;">OLD HEAD PLASTER</h1>
          <p style="color: #A8935C; font-size: 12px; letter-spacing: 3px; margin: 8px 0 0;">ARTISAN DECORATIVE FINISHES</p>
        </div>

        <div style="padding: 40px;">
          <p style="font-size: 16px; line-height: 1.6;">Dear ${clientName},</p>

          <p style="font-size: 15px; line-height: 1.6;">
            Thank you for your interest in Old Head Plaster. Please find your project estimate ${pdfFile ? 'attached to this email' : 'summarized below'}.
          </p>

          <div style="background: #F5F3EF; border-left: 3px solid #A8935C; padding: 20px; margin: 25px 0;">
            <p style="margin: 0 0 8px; font-size: 14px; color: #666;">PROJECT ESTIMATE</p>
            ${quoteNumber ? `<p style="margin: 4px 0; font-size: 13px; color: #999;">${quoteNumber}</p>` : ''}
            ${projectName ? `<p style="margin: 4px 0; font-size: 15px;"><strong>Project:</strong> ${projectName}</p>` : ''}
            ${location ? `<p style="margin: 4px 0; font-size: 15px;"><strong>Location:</strong> ${location}</p>` : ''}
            <p style="margin: 4px 0; font-size: 15px;"><strong>Finish:</strong> ${finishType || 'Venetian Plaster'}</p>
            <p style="margin: 4px 0; font-size: 15px;"><strong>Tier:</strong> ${tier || 'Signature'}</p>
            <p style="margin: 4px 0; font-size: 15px;"><strong>Total Area:</strong> ${totalSqFt} sq ft</p>
            <p style="margin: 4px 0; font-size: 15px;"><strong>Estimate Range:</strong> ${estimateRange}</p>
          </div>

          <h3 style="color: #2C2C2C; font-size: 16px; margin-top: 30px;">What's Included</h3>
          <ul style="font-size: 15px; line-height: 1.8; padding-left: 20px;">
            <li>On-site consultation & measurements</li>
            <li>Custom sample creation (up to 3)</li>
            <li>All materials & specialized tools</li>
            <li>Surface preparation & priming</li>
            <li>Multi-coat plaster application</li>
            <li>Protective sealer application</li>
            <li>Final walkthrough & care guide</li>
          </ul>

          <h3 style="color: #2C2C2C; font-size: 16px; margin-top: 30px;">Next Steps</h3>
          <ol style="font-size: 15px; line-height: 1.8; padding-left: 20px;">
            <li>Schedule a consultation to review your space</li>
            <li>We'll create custom samples for your approval</li>
            <li>Once approved, we'll schedule your project</li>
          </ol>

          <p style="font-size: 15px; line-height: 1.6; margin-top: 25px;">
            Please reply to this email or call 860-574-7004 to schedule your consultation.
          </p>

          <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #E5E5E5;">
            <p style="margin: 0; font-size: 15px;"><strong>Daragh McLoughlin</strong></p>
            <p style="margin: 4px 0; font-size: 14px; color: #666;">Old Head Plaster LLC</p>
            <p style="margin: 4px 0; font-size: 14px; color: #666;">860-574-7004</p>
            <p style="margin: 4px 0; font-size: 14px;">
              <a href="https://oldheadplaster.com" style="color: #A8935C;">oldheadplaster.com</a>
            </p>
            <p style="margin: 8px 0 0; font-size: 12px; color: #999;">CT HIC Reg. #0647302</p>
          </div>
        </div>
      </div>
    `;

    const emailText = `Dear ${clientName},

Thank you for your interest in Old Head Plaster. Please find your project estimate ${pdfFile ? 'attached to this email' : 'summarized below'}.

PROJECT ESTIMATE
${quoteNumber || ''}${projectLine}
${location ? `Location: ${location}` : ''}
Finish: ${finishType || 'Venetian Plaster'}
Tier: ${tier || 'Signature'}
Total Area: ${totalSqFt} sq ft
Estimate Range: ${estimateRange}

WHAT'S INCLUDED
• On-site consultation & measurements
• Custom sample creation (up to 3)
• All materials & specialized tools
• Surface preparation & priming
• Multi-coat plaster application
• Protective sealer application
• Final walkthrough & care guide

NEXT STEPS
1. Schedule a consultation to review your space
2. We'll create custom samples for your approval
3. Once approved, we'll schedule your project

Please reply to this email or call 860-574-7004 to schedule your consultation.

Daragh McLoughlin
Old Head Plaster LLC
860-574-7004
oldheadplaster.com
CT HIC Reg. #0647302`;

    const emailPayload: Record<string, any> = {
      from: 'Daragh McLoughlin <daragh@soullab.life>',
      reply_to: 'daraghmcloughlin1982@gmail.com',
      to: [clientEmail],
      subject: `Old Head Plaster — Project Estimate${projectName ? ` for ${projectName}` : ''}`,
      html: emailHtml,
      text: emailText,
    };

    if (pdfFile) {
      const pdfBuffer = await pdfFile.arrayBuffer();
      const pdfBase64 = Buffer.from(pdfBuffer).toString('base64');
      emailPayload.attachments = [
        {
          filename: `OldHeadPlaster_Estimate_${clientName.replace(/\s+/g, '_')}.pdf`,
          content: pdfBase64,
        }
      ];
    }

    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${resendApiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(emailPayload)
    });

    const result = await response.json();

    if (response.ok) {
      // Also send SMS notification if phone provided
      const twilioSid = process.env.TWILIO_ACCOUNT_SID;
      const twilioToken = process.env.TWILIO_AUTH_TOKEN;
      const twilioPhone = process.env.TWILIO_FROM_NUMBER || process.env.TWILIO_PHONE_NUMBER;

      let smsSent = false;
      if (clientPhone && twilioSid && twilioToken && twilioPhone) {
        try {
          let formattedPhone = clientPhone.replace(/\D/g, '');
          if (formattedPhone.length === 10) formattedPhone = '1' + formattedPhone;
          if (!formattedPhone.startsWith('+')) formattedPhone = '+' + formattedPhone;

          const smsBody = `Hi ${clientName}! Your Old Head Plaster project estimate has been sent to ${clientEmail}. Total area: ${totalSqFt} sq ft, range: ${estimateRange}. Questions? Reply here or call 860-574-7004. — Daragh`;

          const smsResponse = await fetch(
            `https://api.twilio.com/2010-04-01/Accounts/${twilioSid}/Messages.json`,
            {
              method: 'POST',
              headers: {
                'Authorization': 'Basic ' + Buffer.from(`${twilioSid}:${twilioToken}`).toString('base64'),
                'Content-Type': 'application/x-www-form-urlencoded'
              },
              body: new URLSearchParams({
                To: formattedPhone,
                From: twilioPhone,
                Body: smsBody
              })
            }
          );
          smsSent = smsResponse.ok;
        } catch (e) {
          console.error('SMS notification failed:', e);
        }
      }

      return new Response(
        JSON.stringify({
          success: true,
          emailId: result.id,
          smsSent,
          message: `Estimate sent to ${clientEmail}${smsSent ? ' (SMS notification also sent)' : ''}`
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    } else {
      console.error('Resend error:', result);
      return new Response(
        JSON.stringify({ success: false, error: result.message || 'Failed to send email' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

  } catch (error) {
    console.error('Send estimate error:', error);
    return new Response(
      JSON.stringify({ success: false, error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
};
