import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import viteTsconfigPaths from "vite-tsconfig-paths";
import commonjs from "vite-plugin-commonjs";

// https://vitejs.dev/config/
export default defineConfig({
  root: "./src",
  build: {
    outDir: "../dist",
  },
  plugins: [
    react(),
    viteTsconfigPaths(),
    commonjs(),
  ],
  resolve: {
    alias: {
      timers: "rollup-plugin-node-polyfills/polyfills/timers",
      constants: "rollup-plugin-node-polyfills/polyfills/constants",
      process: "rollup-plugin-node-polyfills/polyfills/process-es6",
      os: "rollup-plugin-node-polyfills/polyfills/os",
      path: "rollup-plugin-node-polyfills/polyfills/path",
      stream: "stream-browserify",
      crypto: "crypto-browserify",
      buffer: "buffer",
      fs: "browserify-fs",
    },
  },
  server: {
    port: 3001,
  },
});
