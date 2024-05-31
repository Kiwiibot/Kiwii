import { defineConfig } from "astro/config";
import node from "@astrojs/node";
import { resolve } from "path";
import tailwind from "@astrojs/tailwind";

import solidJs from "@astrojs/solid-js";

// https://astro.build/config
export default defineConfig({
  output: "server",
  adapter: node({
    mode: "standalone"
  }),
  vite: {
    resolve: {
      alias: {
        "~": resolve("./src")
      }
    }
  },
  integrations: [tailwind(), solidJs()]
});