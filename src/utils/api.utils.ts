import type {
  APIGatewayProxyEvent,
  APIGatewayProxyWithCognitoAuthorizerEvent,
  APIGatewayRequestAuthorizerEvent,
} from "aws-lambda";
import camelcaseKeys from "camelcase-keys";
import createError from "http-errors";
import { ZodError, ZodSchema } from "zod";

export const getQueryParam = (
  event: APIGatewayProxyEvent | APIGatewayRequestAuthorizerEvent,
  queryParamName: string,
) => {
  const queryParams = event.queryStringParameters ?? {};
  return Object.entries(queryParams).find(([key]) => key.toLowerCase() === queryParamName.toLowerCase())?.[1];
};

export const getHeader = (event: APIGatewayProxyEvent, headerName: string) => {
  const headers = event.headers ?? {};
  return Object.entries(headers).find(([key, _]) => key.toLowerCase() === headerName.toLowerCase())?.[1];
};

export const getPath = (url: string, withQuery = false) => {
  const parsedUrl = new URL(url);

  const path = withQuery ? `${parsedUrl.pathname}${parsedUrl.search}` : parsedUrl.pathname;

  return path;
};

export const getPathParam = (event: APIGatewayProxyEvent, pathParamName: string) => {
  const pathParams = event.pathParameters ?? {};

  return pathParams[pathParamName];
};

export const parseBody = <T>(body: APIGatewayProxyEvent["body"]) => {
  if (!body) return null;

  try {
    return camelcaseKeys(JSON.parse(body), {
      deep: true,
    }) as unknown as T;
  } catch {
    return null;
  }
};

export const parseAndValidateBody = <T>(eventBody: APIGatewayProxyEvent["body"], schema: ZodSchema<T>) => {
  const body = camelcaseKeys(JSON.parse(eventBody ?? "{}"), {
    deep: true,
  }) as unknown;

  try {
    return schema.parse(body);
  } catch (error) {
    if (error instanceof ZodError) throw createError(400, JSON.stringify(error.issues));
    throw error;
  }
};

export const getCurrentUsername = <T = string>(event: APIGatewayProxyWithCognitoAuthorizerEvent) => {
  return event.requestContext.authorizer?.claims.username as T;
};
