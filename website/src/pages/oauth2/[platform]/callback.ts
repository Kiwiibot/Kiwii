import { type APIContext } from "astro";

export const allowedPlatforms = ["discord"] as const;

export const GET = async (
  ctx: APIContext<any, { platform: (typeof allowedPlatforms)[number] }>
) => {
  if (!allowedPlatforms.includes(ctx.params.platform)) {
    return new Response("Invalid platform", {
      status: 400,
      headers: { "Content-Type": "text/plain" },
    });
  }

  const isRefresh = ctx.url.searchParams.has("refresh");

  if (
    (!ctx.url.searchParams.has("state") ||
      atob(ctx.url.searchParams.get("state")!) !==
        ctx.cookies.get("state")!.value) &&
    !isRefresh
  ) {
    return new Response("Invalid state, you may be a victim of CSRF", {
      status: 400,
      headers: {
        "Content-Type": "text/plain",
      },
    });
  }

  const params = new URLSearchParams();

  params.append("client_id", import.meta.env.DISCORD_CLIENT_ID);
  params.append("client_secret", import.meta.env.DISCORD_CLIENT_SECRET);
  params.append(
    "grant_type",
    isRefresh ? "refresh_token" : "authorization_code"
  );
  if (!isRefresh) {
    params.append("code", ctx.url.searchParams.get("code")!);
    params.append("redirect_uri", import.meta.env.DISCORD_REDIRECT_URI);
  } else {
    params.append("refresh_token", ctx.cookies.get("refresh_token")!.value);
  }

  const response = await fetch("https://discord.com/api/v10/oauth2/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: params,
  });

  const data = await response.json();

  ctx.cookies.set("access_token", data.access_token, {
    expires: new Date(Date.now() + data.expires_in * 1000),
    path: "/",
    httpOnly: true,
    secure: true,
  });

  ctx.cookies.set("refresh_token", data.refresh_token, {
    expires: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    path: "/",
    httpOnly: true,
    secure: true,
  });

  return ctx.redirect("/");
};
