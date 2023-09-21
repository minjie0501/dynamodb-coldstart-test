import terraformOutputs from "../../build/terraform-outputs.json";
import { EnvConfig } from "./types";

const envConfig: Record<string, EnvConfig> = {
  local: {
    cors_domain: "*",
  },
  stag: {
    cors_domain: "*",
  },
  prod: {
    cors_domain: "*",
  },
};

// TODO: check why IS_LOCAL is undefined when using sls offline
const env = process.env.IS_LOCAL || process.env.IS_OFFLINE ? "local" : process.env.ENV ?? "local";

export const config = {
  ...terraformOutputs,
  ...(envConfig[env] ?? {}),
} as const;
