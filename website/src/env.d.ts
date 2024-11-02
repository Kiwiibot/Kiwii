/// <reference path="../.astro/types.d.ts" />
/// <reference types="astro/client" />
/// <reference types="discord-api-types/v10" />
/// <reference types="@skyra/discord-components-core" />

import '@skyra/discord-components-core';

interface ImportMetaEnv {
  readonly DISCORD_CLIENT_ID: string;
  readonly DISCORD_CLIENT_SECRET: string;
  readonly DISCORD_REDIRECT_URI: string;
  readonly API_URL: string;
}

namespace App {
  interface Locals {
    // Like, what is this? TypeScript is so confusing
    member: import("discord-api-types/v10").APIGuildMember;

    /**
     * Whether or not the client is a member of the server
     */
    isUnknownGuild?: boolean;

    /**
     * The guild
     */
    guild?: import("discord-api-types/v10").APIGuild;

    guildName?: string;
  }
}

declare module "solid-js" {
  namespace JSX {
    type ElementProps<T> = {
      [K in keyof T]: Props<T[K]> & HTMLAttributes<T[K]>;
    };

    type Props<T> = {
      [K in keyof T as `prop:${string & K}`]?: T[K];
    };

    interface IntrinsicElements extends ElementProps<HTMLElementTagNameMap> {
      "discord-messages": { test: string };
    }
  }
}
