# Token Usage Tracker Rule

Only show a token usage estimate when the user **explicitly asks** for it. Trigger phrases include (but are not limited to):
- "show usage"
- "token usage"
- "how many tokens"
- "usage metrics"
- "usage stats"
- "show metrics"

When triggered, respond with the following format:

```
📊 **Usage Estimate**
- **Input tokens**: ~{input_tokens}
- **Output tokens**: ~{output_tokens}
- **Total tokens**: ~{total_tokens}
- **Model**: {model_name}
- **Context remaining**: ~{remaining_tokens} of 200,000
```

## How to Estimate Tokens

Use these approximations:

- **Input tokens**: Count all text in the conversation so far (user messages + your previous responses + system context). Estimate ~1 token per 4 characters. Add ~2,000–4,000 tokens for system prompt/context overhead.
- **Output tokens**: Estimate ~1 token per 4 characters of your current response.
- **Total tokens**: input_tokens + output_tokens.
- **Remaining tokens**: 200,000 - total_tokens (Claude Sonnet 4.6 context window).
- **Model name**: Use the current model name (e.g., `Claude Sonnet 4.6 Thinking`).

## Rules

1. Only show the usage block when the user explicitly asks — never on every response.
2. Round estimates to the nearest 100 for readability.
3. Use `~` prefix to indicate these are estimates, not exact values.
4. Do NOT add extra explanation about the estimates unless the user asks.
