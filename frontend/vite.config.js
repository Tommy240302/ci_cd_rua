import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  server: {
    host: true,
    strictPort: true,
    port: parseInt(process.env.VITE_PORT),
    https:false
  },
  plugins: [react()],
})
