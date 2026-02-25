import type { APIRoute } from 'astro';
import puppeteer from 'puppeteer-core';
import chromium from '@sparticuz/chromium-min';

export const prerender = false;

export const POST: APIRoute = async ({ request }) => {
  let browser = null;
  try {
    const { html } = await request.json();
    if (!html) {
      return new Response(JSON.stringify({ error: 'html is required' }), {
        status: 400, headers: { 'Content-Type': 'application/json' }
      });
    }

    // Launch headless browser
    browser = await puppeteer.launch({
      args: chromium.args,
      executablePath: await chromium.executablePath(
        'https://github.com/Sparticuz/chromium/releases/download/v131.0.1/chromium-v131.0.1-pack.tar'
      ),
      headless: true,
    });

    const page = await browser.newPage();
    await page.setContent(html, { waitUntil: 'networkidle0', timeout: 30000 });

    const pdfBuffer = await page.pdf({
      format: 'Letter',
      printBackground: true,
      margin: { top: 0, right: 0, bottom: 0, left: 0 },
    });

    return new Response(pdfBuffer, {
      status: 200,
      headers: {
        'Content-Type': 'application/pdf',
        'Content-Disposition': 'attachment; filename="contract.pdf"',
      }
    });

  } catch (error) {
    console.error('PDF generation error:', error);
    return new Response(JSON.stringify({ error: 'PDF generation failed', detail: String(error) }), {
      status: 500, headers: { 'Content-Type': 'application/json' }
    });
  } finally {
    if (browser) await browser.close();
  }
};
