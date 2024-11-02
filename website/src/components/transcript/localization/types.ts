export type Language = "en-GB" | "fr-FR" | "de-DE";

export type DotNotation<T> = T extends string[]
  ? ""
  : T extends object
  ? {
      [K in keyof T]: T[K] extends object
        ? `${K & string}.${DotNotation<T[K]>}`
        : K;
    }[keyof T]
  : T & string;

export interface Messages {
  title: {
    dm: string;
  };
}
