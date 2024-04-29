const utils = {
  randomRange(min: number, max: number): number {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  },

  formatNumberK(number: number): string {
    if (number > 999999999) {
      return `${
        (number / 1000000000).toLocaleString(undefined, {
          maximumFractionDigits: 1,
        })
      }B`;
    }
    if (number > 999999) {
      return `${
        (number / 1000000).toLocaleString(undefined, {
          maximumFractionDigits: 1,
        })
      }M`;
    }
    if (number > 999) {
      return `${
        (number / 1000).toLocaleString(undefined, { maximumFractionDigits: 1 })
      }K`;
    }
    return number.toString();
  },
};

export default utils;
