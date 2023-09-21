import { Entity } from "electrodb";
import { z } from "zod";

import { dynamodbClient } from "clients/dynamoClient";

export const User = new Entity(
  {
    model: {
      entity: "user",
      version: "1",
      service: "app",
    },
    attributes: {
      userId: {
        type: "string",
        required: true,
      },
      email: {
        type: "string",
        required: true,
        validate: (email: string) => {
          z.string().email().parse(email);
        },
      },
    },
    indexes: {
      user: {
        pk: {
          field: "pk",
          composite: ["userId"],
        },
        sk: {
          field: "sk",
          composite: [],
        },
      },
    },
  },
  { client: dynamodbClient, table: "coldstart" },
);
