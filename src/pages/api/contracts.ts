import type { APIRoute } from 'astro';
import { promises as fs } from 'fs';
import path from 'path';

export const prerender = false;

const DATA_DIR = path.join(process.cwd(), 'data');
const CONTRACTS_FILE = path.join(DATA_DIR, 'contracts.json');

// Ensure data directory and file exist
async function ensureDataFile() {
  try {
    await fs.mkdir(DATA_DIR, { recursive: true });
    try {
      await fs.access(CONTRACTS_FILE);
    } catch {
      await fs.writeFile(CONTRACTS_FILE, JSON.stringify([], null, 2));
    }
  } catch (e) {
    console.error('Failed to ensure data file:', e);
  }
}

async function readContracts() {
  await ensureDataFile();
  try {
    const data = await fs.readFile(CONTRACTS_FILE, 'utf-8');
    return JSON.parse(data);
  } catch {
    return [];
  }
}

async function writeContracts(contracts: any[]) {
  await ensureDataFile();
  await fs.writeFile(CONTRACTS_FILE, JSON.stringify(contracts, null, 2));
}

// GET - List all contracts (with optional search)
export const GET: APIRoute = async ({ url }) => {
  try {
    const contracts = await readContracts();
    const search = url.searchParams.get('search')?.toLowerCase();
    const status = url.searchParams.get('status');

    let filtered = contracts;

    if (search) {
      filtered = filtered.filter((c: any) =>
        c.clientName?.toLowerCase().includes(search) ||
        c.contractNumber?.toLowerCase().includes(search) ||
        c.clientEmail?.toLowerCase().includes(search)
      );
    }

    if (status) {
      filtered = filtered.filter((c: any) => c.status === status);
    }

    // Sort by most recent first
    filtered.sort((a: any, b: any) =>
      new Date(b.updatedAt || b.createdAt).getTime() - new Date(a.updatedAt || a.createdAt).getTime()
    );

    return new Response(
      JSON.stringify({ success: true, contracts: filtered, total: contracts.length }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Failed to read contracts:', error);
    return new Response(
      JSON.stringify({ success: false, error: 'Failed to read contracts' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
};

// POST - Create or update a contract
export const POST: APIRoute = async ({ request }) => {
  try {
    const body = await request.json();
    const contracts = await readContracts();
    const now = new Date().toISOString();

    // Check if updating existing contract
    const existingIndex = contracts.findIndex((c: any) => c.id === body.id);

    if (existingIndex !== -1) {
      // Update existing
      contracts[existingIndex] = {
        ...contracts[existingIndex],
        ...body,
        updatedAt: now
      };
    } else {
      // Create new
      const contract = {
        id: body.id || `contract-${Date.now()}-${Math.random().toString(36).substr(2, 6)}`,
        contractNumber: body.contractNumber || '',
        clientName: body.clientName || '',
        clientEmail: body.clientEmail || '',
        clientPhone: body.clientPhone || '',
        clientAddress: body.clientAddress || '',
        amount: body.amount || '$0',
        status: body.status || 'draft',
        bespokeMode: body.bespokeMode || false,
        sections: body.sections || [],
        timeline: body.timeline || {},
        warranty: body.warranty || '3-year limited workmanship',
        notes: body.notes || '',
        createdAt: now,
        updatedAt: now,
        sentAt: body.sentAt || null,
        signedAt: body.signedAt || null
      };
      contracts.unshift(contract);
    }

    await writeContracts(contracts);

    const saved = existingIndex !== -1
      ? contracts[existingIndex]
      : contracts[0];

    return new Response(
      JSON.stringify({ success: true, contract: saved }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Failed to save contract:', error);
    return new Response(
      JSON.stringify({ success: false, error: 'Failed to save contract' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
};

// DELETE - Remove a contract
export const DELETE: APIRoute = async ({ url }) => {
  try {
    const id = url.searchParams.get('id');
    if (!id) {
      return new Response(
        JSON.stringify({ success: false, error: 'Contract ID required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const contracts = await readContracts();
    const filtered = contracts.filter((c: any) => c.id !== id);

    if (filtered.length === contracts.length) {
      return new Response(
        JSON.stringify({ success: false, error: 'Contract not found' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    await writeContracts(filtered);

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Failed to delete contract:', error);
    return new Response(
      JSON.stringify({ success: false, error: 'Failed to delete contract' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
};
