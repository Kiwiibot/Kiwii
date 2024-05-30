import { LRUCache } from "lru-cache";

function generateRandomString(length: number = 20): string {
  const characters =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let result = "";
  const randomNumber = Math.floor(Math.random() * 10);
  for (let i = 0; i < length + randomNumber; i++) {
    result += characters.charAt(Math.floor(Math.random() * characters.length));
  }
  return result;
}

let _cache: LRUCache<string, object> | null = null;

const cache =
  _cache ??
  (() => {
    if (!_cache) {
      _cache = new LRUCache<string, object>({
        max: 500,
      });
    }
    return _cache;
  })();

export { generateRandomString, cache };
