import { defineMiddleware } from "astro:middleware";
import { PermissionFlagsBits } from "discord-api-types/v10";

export const onRequest = defineMiddleware(async (ctx, next) => {
  if (ctx.url.pathname.includes("/guilds/")) {
    if (!ctx.cookies.has("access_token")) {
      return ctx.redirect("/errors/unauthorized");
    }

    if (!ctx.locals.member && ctx.params.guildId) {
      const memberData = await fetch(
        `https://discord.com/api/v10/users/@me/guilds/${ctx.params.guildId}/member`,
        {
          headers: {
            Authorization: `Bearer ${ctx.cookies.get("access_token")!.value}`,
          },
        }
      );

      if (!memberData.ok) {
        ctx.cookies.set("error", "You are not a member of this server.", {
          path: "/errors/unauthorized",
        });
        return ctx.redirect("/errors/unauthorized");
      }

      const member = await memberData.json();
      ctx.locals.member = member;
    }

    const { member } = ctx.locals;

    if (ctx.url.pathname.includes("/moderation/")) {
      const permissionsData = await fetch(
        `${import.meta.env.API_URL}/permissions/${ctx.params.guildId}/${
          member.user?.id
        }`
      );

      if (!permissionsData.ok) {
        if (permissionsData.status === 404) {
          // Likely the client isn't a member of the server, but for the sake of the continuity we'll just next() here, and handle this case in the `/guilds/[guildId]/` route.
          ctx.locals.isUnknownGuild = true;
          return next();
        }

        ctx.cookies.set(
          "error",
          "You do not have permission to access this page.",
          {
            path: "/errors/unauthorized",
          }
        );
        return ctx.redirect("/errors/unauthorized");
      }

      const { permissions } = await permissionsData.json();

      if ((BigInt(permissions) & PermissionFlagsBits.ModerateMembers) === 0n) {
        ctx.cookies.set(
          "error",
          "You do not have permission to access this page.",
          {
            path: "/errors/unauthorized",
          }
        );
        return ctx.redirect("/errors/unauthorized");
      }
    }

    if (!ctx.locals.guild && ctx.params.guildId) {
      const guildData = await fetch(
        `${import.meta.env.API_URL}/guilds/${ctx.params.guildId}`,
        {
          headers: {
            Authorization: `Bearer ${ctx.cookies.get("access_token")!.value}`,
          },
        }
      );

      const guild = await guildData.json();

      ctx.locals.guild = guild;
    }
  }

  return next();
});
