import type { APIRoute } from 'astro';

export const prerender = false;

const PDF_SERVICE_URL = process.env.PDF_SERVICE_URL || 'http://minisforum:3033';

export const POST: APIRoute = async ({ request }) => {
  try {
    const { html, filename } = await request.json();

    if (!html) {
      return new Response(
        JSON.stringify({ error: 'html is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const upstream = await fetch(`${PDF_SERVICE_URL}/pdf`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ html, filename }),
    });

    if (!upstream.ok) {
      const err = await upstream.text();
      console.error('pdf-service error:', err);
      return new Response(
        JSON.stringify({ error: 'PDF generation failed' }),
        { status: 502, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const pdfBuffer = await upstream.arrayBuffer();

    return new Response(pdfBuffer, {
      status: 200,
      headers: {
        'Content-Type': 'application/pdf',
        'Content-Disposition': `attachment; filename="${filename || 'document.pdf'}"`,
        'Content-Length': pdfBuffer.byteLength.toString(),
      },
    });
  } catch (err) {
    console.error('generate-pdf proxy error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
};
