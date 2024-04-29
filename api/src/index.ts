import fastify from "fastify";

import routesV1 from "./routes/v1/index.js";

const app = fastify({logger: true});

app.register(routesV1, { prefix: "/api/v1" });

await app.listen({
  port: 3000,
  host: "0.0.0.0",
});
