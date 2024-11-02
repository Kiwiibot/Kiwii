import type { APIRoute } from "astro";

export const GET: APIRoute = async (context) => {
  const response = await fetch(`${new URL(context.request.url).origin}/yo`);

  return response;
};
