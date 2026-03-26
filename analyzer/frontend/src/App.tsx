import { useEffect, useState } from 'react';
import { fetchFlows } from './api';
import type { FlowSummary } from './types';

function App() {
  const [flows, setFlows] = useState<FlowSummary[]>([]);

  useEffect(() => {
    fetchFlows({ limit: 20 }).then((r) => setFlows(r.flows));
  }, []);

  return (
    <main>
      <h1>agent-analyzer</h1>
      <ul>
        {flows.map((f) => (
          <li key={f.id}>{f.host}{f.path}</li>
        ))}
      </ul>
    </main>
  );
}

export default App;
