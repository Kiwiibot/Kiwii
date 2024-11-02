import { defineConfig } from "astro/config";
import node from "@astrojs/node";
import { resolve } from "path";
import tailwind from "@astrojs/tailwind";
import solidJs from "@astrojs/solid-js";
import react from "@astrojs/react";

import lit from "@astrojs/lit";

// https://astro.build/config
export default defineConfig({
  output: "server",
  adapter: node({
    mode: "standalone",
  }),
  vite: {
    resolve: {
      alias: {
        "~": resolve("./src"),
      },
    },
    optimizeDeps: {
      exclude: ["@napi-rs/"],
    },
    server: {
      fs: {
        allow: [".", resolve(process.env.HOME, ".local", "share", "pnpm")],
      },
    },
  },
  integrations: [
    tailwind(),
    solidJs({
      include: "src/solid/**",
    }),
    react({
      include: "src/react/**",
    }),
    lit({
      include: "src/lit/**",
    }),
  ],
});
