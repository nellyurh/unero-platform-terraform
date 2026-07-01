# module: eventbridge-bus

One custom bus per environment. Archive on (replay), schema discovery on (feeds ADR-022
client generation). Events reach the bus only via the Outbox relay, never directly from a
business transaction path (AI_RULES Events).
