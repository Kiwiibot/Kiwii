/// <reference types="astro/client" />
/// <reference types="discord-api-types/v10" />

interface ImportMetaEnv {
  readonly DISCORD_CLIENT_ID: string;
  readonly DISCORD_CLIENT_SECRET: string;
  readonly DISCORD_REDIRECT_URI: string;
  readonly API_URL: string;
}

namespace App {
  interface Locals {
    // Like, what is this? TypeScript is so confusing
    member: import('discord-api-types/v10').APIGuildMember;

    /**
     * Whether or not the client is a member of the server
     */
    isUnknownGuild?: boolean;

    /**
     * The guild
     */
    guild?: import('discord-api-types/v10').APIGuild;

    guildName?: string;
  }
}
