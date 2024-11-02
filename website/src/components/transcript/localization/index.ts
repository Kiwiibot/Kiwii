import { format } from "node:util";

import type { DotNotation, Language, Messages } from "./types";

import enGB from "./messages/en-GB";

let mappings: Record<Language, Messages | null> = {
  "en-GB": enGB,
  "de-DE": null,
  "fr-FR": null,
};

export class Lang<T extends Language> {
  readonly #t: Messages;

  constructor(public language: T) {
    let t: Messages | null;

    if ((t = mappings[language])) {
      this.#t = t;
    } else {
      throw new Error(`Language not supported: ${language}`);
    }
  }

  public format(path: DotNotation<Messages>, ...args: unknown[]): string {
    const value = this.#extractValue(path);

    return format(value, ...args);
  }

  #extractValue(path: DotNotation<Messages>): string {
    // Path is a string like "test" or "nested.key", the depth of the object is unknown
    const parts = path.split(".");
    let value = this.#t;

    for (const part of parts) {
      if (part in value) {
        // @ts-expect-error: it's fine
        value = value[part];
      } else {
        throw new Error(`Invalid path: ${path}`);
      }
    }

    return <string>(<unknown>value);
  }
}

export function t(
  path: DotNotation<Messages>,
  language: Language,
  ...args: unknown[]
): string {
  return new Lang(language).format(path, ...args);
}
