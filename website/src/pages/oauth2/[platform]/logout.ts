import type { APIContext } from "astro";
import { allowedPlatforms } from "./callback";

export const GET = async (
  ctx: APIContext<any, { platform: (typeof allowedPlatforms)[number] }>
) => {
  if (!allowedPlatforms.includes(ctx.params.platform)) {
    return new Response("Invalid platform", {
      status: 400,
      headers: { "Content-Type": "text/plain" },
    });
  }

  ctx.cookies.delete("access_token", { path: "/" });
  ctx.cookies.delete("refresh_token", { path: "/" });
  ctx.cookies.delete("state", { path: "/" });

  return ctx.redirect("/");
};
