export const isLocal = () => {
  return process.env.ENV?.toLowerCase() === "local" || process.env.IS_LOCAL === "true";
};

export const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));
