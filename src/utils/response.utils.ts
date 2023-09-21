import { APIGatewayProxyResult } from "aws-lambda";
import errorResponseFactory from "http-errors";

type Headers = {
  [key: string]: string;
};

type Body = {
  [key: string]: string | object | boolean;
};

type SuccessResponse = {
  code?: number;
  body?: Body | Array<Body>;
  headers?: Headers;
  cache?: number;
  corsOverwrite?: CorsOverwrite;
};

type CorsOverwrite = {
  allowedCorsDomains: Array<string>;
  currentOrigin: string;
};

export const successResponse = ({ code = 200, body = {}, headers = {}, cache = 0 }: SuccessResponse) => {
  const headerKeys = Object.keys(headers).map((key) => key.toLowerCase());
  if (!headerKeys.includes("content-type")) {
    headers["Content-Type"] = "application/json";
  }

  if (cache > 0) {
    headers["Cache-Control"] = `public, max-age=${cache}, s-maxage=${cache}`;
  } else {
    headers["Cache-Control"] = "no-cache";
  }

  return {
    statusCode: code,
    headers,
    body: JSON.stringify(body),
  } as APIGatewayProxyResult;
};

export const errorResponse = (statusCode: number, errorMessage: string) => {
  return errorResponseFactory(statusCode, JSON.stringify({ error: errorMessage }));
};
