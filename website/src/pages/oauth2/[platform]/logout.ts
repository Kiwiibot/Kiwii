import type { APIContext } from "astro";
import { allowedPlatforms } from "./callback";

export const GET = async (ctx: APIContext) => {
  if (!allowedPlatforms.includes(ctx.params.platform! as "discord")) {
    return new Response("Invalid platform", {
      status: 400,
      headers: { "Content-Type": "text/plain" },
    });
  }

  ctx.cookies.delete("access_token", { path: "/" });
  ctx.cookies.delete("refresh_token", { path: "/" });

  return ctx.redirect("/");
};
