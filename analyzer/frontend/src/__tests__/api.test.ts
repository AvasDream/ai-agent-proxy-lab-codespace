import { fetchFlows } from '../api';

describe('fetchFlows', () => {
  it('calls /api/flows with query params', async () => {
    (global.fetch as unknown as any).mockResolvedValue({
      json: async () => ({ total: 0, limit: 100, offset: 0, flows: [] }),
    });

    await fetchFlows({ flow_type: 'ai', limit: 50 });
    const called = (global.fetch as unknown as any).mock.calls[0][0];
    expect(called).toContain('/api/flows');
    expect(called).toContain('flow_type=ai');
    expect(called).toContain('limit=50');
  });
});
