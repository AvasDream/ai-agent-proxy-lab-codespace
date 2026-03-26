import type { FlowListResponse } from './types';

const API_BASE = '/api';

export async function fetchFlows(params: Record<string, string | number | boolean>): Promise<FlowListResponse> {
  const qs = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) {
    if (v !== undefined && v !== null && v !== '') qs.set(k, String(v));
  }
  const res = await fetch(`${API_BASE}/flows?${qs.toString()}`);
  return res.json();
}
