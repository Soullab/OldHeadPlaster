import type { APIRoute } from 'astro';

export const prerender = false;

export const POST: APIRoute = async ({ request }) => {
  try {
    const formData = await request.formData();

    const clientName = formData.get('clientName') as string;
    const clientEmail = formData.get('clientEmail') as string;
    const clientPhone = formData.get('clientPhone') as string;
    const contractNumber = formData.get('contractNumber') as string;
    const totalSqFt = formData.get('totalSqFt') as string;
    const estimateRange = formData.get('estimateRange') as string;
    const agreedPrice = formData.get('agreedPrice') as string;
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

    const resendApiKey = import.meta.env.RESEND_API_KEY;
    if (!resendApiKey) {
      return new Response(
        JSON.stringify({ success: false, error: 'Email service not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Build the email body
    const priceDisplay = agreedPrice
      ? `Agreed Price: $${agreedPrice}`
      : `Estimate Range: ${estimateRange}`;

    const emailHtml = `
      <div style="font-family: Georgia, serif; color: #333; max-width: 600px; margin: 0 auto;">
        <div style="background: #2C2C2C; padding: 30px 40px; text-align: center;">
          <h1 style="color: #FAFAF8; font-size: 24px; letter-spacing: 2px; margin: 0;">OLD HEAD PLASTER</h1>
          <p style="color: #A8935C; font-size: 12px; letter-spacing: 3px; margin: 8px 0 0;">ARTISAN DECORATIVE FINISHES</p>
        </div>

        <div style="padding: 40px;">
          <p style="font-size: 16px; line-height: 1.6;">Dear ${clientName},</p>

          <p style="font-size: 15px; line-height: 1.6;">
            Thank you for considering Old Head Plaster for your project. Please find your Service Agreement attached to this email.
          </p>

          <div style="background: #F5F3EF; border-left: 3px solid #A8935C; padding: 20px; margin: 25px 0;">
            <p style="margin: 0 0 8px; font-size: 14px; color: #666;">PROJECT SUMMARY</p>
            <p style="margin: 4px 0; font-size: 15px;"><strong>Contract:</strong> ${contractNumber}</p>
            <p style="margin: 4px 0; font-size: 15px;"><strong>Total Area:</strong> ${totalSqFt} sq ft</p>
            <p style="margin: 4px 0; font-size: 15px;"><strong>${priceDisplay}</strong></p>
          </div>

          <h3 style="color: #2C2C2C; font-size: 16px; margin-top: 30px;">Next Steps</h3>
          <ol style="font-size: 15px; line-height: 1.8; padding-left: 20px;">
            <li>Review the attached Service Agreement carefully</li>
            <li>Sign and return the agreement (you can print, sign, and scan — or reply with your electronic signature)</li>
            <li>Submit your deposit to secure scheduling</li>
          </ol>

          <div style="background: #FFFBEB; border: 1px solid #F59E0B; padding: 15px; margin: 25px 0; border-radius: 4px;">
            <p style="margin: 0; font-size: 13px; color: #92400E;">
              <strong>CT Home Improvement Act Notice:</strong> You have the right to cancel this contract within three (3) business days of signing. Details are included in the attached agreement.
            </p>
          </div>

          <p style="font-size: 15px; line-height: 1.6;">
            If you have any questions about the project or agreement, please don't hesitate to reach out.
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

Thank you for considering Old Head Plaster for your project. Please find your Service Agreement attached to this email.

PROJECT SUMMARY
${contractNumber}
Total Area: ${totalSqFt} sq ft
${priceDisplay}

NEXT STEPS
1. Review the attached Service Agreement carefully
2. Sign and return the agreement
3. Submit your deposit to secure scheduling

CT Home Improvement Act Notice: You have the right to cancel this contract within three (3) business days of signing. Details are included in the attached agreement.

If you have any questions, please don't hesitate to reach out.

Daragh McLoughlin
Old Head Plaster LLC
860-574-7004
oldheadplaster.com
CT HIC Reg. #0647302`;

    // Build Resend request body
    const emailPayload: Record<string, any> = {
      from: 'Daragh McLoughlin <daragh@soullab.life>',
      to: [clientEmail],
      subject: `Old Head Plaster — Service Agreement${contractNumber ? ` (${contractNumber})` : ''}`,
      html: emailHtml,
      text: emailText,
    };

    // Attach PDF if provided
    if (pdfFile) {
      const pdfBuffer = await pdfFile.arrayBuffer();
      const pdfBase64 = Buffer.from(pdfBuffer).toString('base64');
      emailPayload.attachments = [
        {
          filename: `OldHeadPlaster_ServiceAgreement_${clientName.replace(/\s+/g, '_')}.pdf`,
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
      const twilioSid = import.meta.env.TWILIO_ACCOUNT_SID;
      const twilioToken = import.meta.env.TWILIO_AUTH_TOKEN;
      const twilioPhone = import.meta.env.TWILIO_PHONE_NUMBER;

      let smsSent = false;
      if (clientPhone && twilioSid && twilioToken && twilioPhone) {
        try {
          let formattedPhone = clientPhone.replace(/\D/g, '');
          if (formattedPhone.length === 10) formattedPhone = '1' + formattedPhone;
          if (!formattedPhone.startsWith('+')) formattedPhone = '+' + formattedPhone;

          const smsBody = `Hi ${clientName}! Your Old Head Plaster Service Agreement has been sent to ${clientEmail}. Please review and sign at your convenience. Questions? Reply here or call 860-574-7004. — Daragh`;

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
          message: `Contract sent to ${clientEmail}${smsSent ? ' (SMS notification also sent)' : ''}`
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
    console.error('Send contract error:', error);
    return new Response(
      JSON.stringify({ success: false, error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
};
