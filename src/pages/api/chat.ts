import type { APIRoute } from 'astro';
import Anthropic from '@anthropic-ai/sdk';
import { DARAGH_SYSTEM_PROMPT } from '../../data/daragh-knowledge';

export const prerender = false;

export const POST: APIRoute = async ({ request }) => {
  try {
    const { messages, systemPrompt } = await request.json();

    if (!messages || !Array.isArray(messages)) {
      return new Response(
        JSON.stringify({ error: 'Messages array is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const apiKey = import.meta.env.ANTHROPIC_API_KEY;

    if (!apiKey) {
      console.error('ANTHROPIC_API_KEY is not set');
      return new Response(
        JSON.stringify({
          message: "I'm temporarily unavailable. Please try again later or contact us directly through the contact page."
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const anthropic = new Anthropic({
      apiKey: apiKey
    });

    // Use custom system prompt if provided, otherwise default to Virtual Daragh
    const effectiveSystemPrompt = systemPrompt || DARAGH_SYSTEM_PROMPT;

    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 1024,
      system: effectiveSystemPrompt,
      messages: messages.map((msg: { role: string; content: string }) => ({
        role: msg.role as 'user' | 'assistant',
        content: msg.content
      }))
    });

    const textContent = response.content.find(block => block.type === 'text');
    const messageText = textContent && 'text' in textContent ? textContent.text : '';

    return new Response(
      JSON.stringify({ message: messageText }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Chat API error:', error);

    return new Response(
      JSON.stringify({
        message: "I'm having trouble processing your request. Please try again or contact us directly."
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  }
};
