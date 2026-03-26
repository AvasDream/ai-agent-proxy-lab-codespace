export interface FlowSummary {
  id: string;
  flow_type: 'ai' | 'auth' | 'other';
  agent: string | null;
  provider: string | null;
  method: string;
  scheme: string;
  host: string;
  path: string;
  query: string;
  status_code: number | null;
  content_type_req: string | null;
  content_type_res: string | null;
  timestamp_start: number;
  timestamp_end: number | null;
  latency_ms: number | null;
  ttfb_ms: number | null;
  request_size: number;
  response_size: number;
  is_error: boolean;
  is_replay: boolean;
  tags: string[];
}

export interface FlowListResponse {
  total: number;
  limit: number;
  offset: number;
  flows: FlowSummary[];
}
