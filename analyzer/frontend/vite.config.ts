import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

const API_PORT = process.env.API_PORT || '5555';
const FRONTEND_PORT = process.env.FRONTEND_PORT || '5173';

export default defineConfig({
  plugins: [react()],
  server: {
    port: parseInt(FRONTEND_PORT, 10),
    proxy: {
      '/api': {
        target: `http://127.0.0.1:${API_PORT}`,
        ws: true,
      },
    },
  },
  build: { outDir: 'dist' },
});
