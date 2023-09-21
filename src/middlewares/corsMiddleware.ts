import middy from "@middy/core";
import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";

import { config } from "config";

type CorsOptions = {
  allowedMethods?: Array<"*" | "GET" | "POST" | "DELETE" | "PUT" | "PATCH" | "CONNECT" | "HEAD" | "OPTIONS" | "TRACE">;
  allowedHeaders?: Array<string>;
  allowedOrigins?: Array<string>;
  allowCredentials?: boolean;
};

const getAllowedOrigin = (event: APIGatewayProxyEvent, allowedOrigins: Array<string>) => {
  const origin = event.headers.origin ?? "";
  if (allowedOrigins.includes("*")) return "*";
  return allowedOrigins.includes(origin) ? origin : config.cors_domain;
};

export const cors = (
  allowedMethods: CorsOptions["allowedMethods"] = ["*"],
  allowedHeaders: CorsOptions["allowedHeaders"] = ["*"],
  allowedOrigins: CorsOptions["allowedOrigins"] = [config.cors_domain],
  allowCredentials: CorsOptions["allowCredentials"] = true,
): middy.MiddlewareObj<APIGatewayProxyEvent, APIGatewayProxyResult> => {
  const handleCors: middy.MiddlewareFn<APIGatewayProxyEvent, APIGatewayProxyResult> = ({ event, response }) => {
    if (!response) return;

    const headers = response?.headers ?? {};

    headers["Access-Control-Allow-Origin"] = getAllowedOrigin(event, allowedOrigins);
    headers["Access-Control-Allow-Methods"] = allowedMethods.join(", ");
    headers["Access-Control-Allow-Headers"] = allowedHeaders.join(", ");
    headers["Access-Control-Allow-Credentials"] = allowCredentials.toString();

    response.headers = headers;
  };
  return {
    after: handleCors,
    onError: handleCors,
  };
};
