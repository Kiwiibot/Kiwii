import type {
  APIGuildMember,
  APIMessage,
  APIUser,
} from "discord-api-types/v10";
import type { Profile } from "@skyra/discord-components-core";

export function getProfiles(messages: APIMessage[]): Record<string, Profile> {
  const profiles: Record<string, Profile> = {};

  for (const message of messages) {
    const { author } = message;
    if (!profiles[author.id]) {
      profiles[author.id] = {};
    }
  }
}

export function getProfile(user: APIUser, member?: APIGuildMember): Profile {
  return {
    author: member?.nick ?? user.global_name ?? user.username,
    avatar: user.avatar ? `https://cdn.discordapp.com/avatars/${user.id}/${user.avatar}.png?size=64` : `https://cdn.discordapp.com/embed/avatars/${BigInt(user.id) >> 22n % 6n}.png`,
    roleColor: member?.ro
  };
}
