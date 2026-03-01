import OpenAI from "openai";
import { config } from "../config/index.js";

const openai = new OpenAI({ apiKey: config.OPENAI_API_KEY });

/**
 * Generate an embedding vector for the given text.
 */
export async function generateEmbedding(text: string): Promise<number[]> {
  const response = await openai.embeddings.create({
    model: config.OPENAI_EMBEDDING_MODEL,
    input: text,
  });
  return response.data[0].embedding;
}

/**
 * Summarize a fragment's content.
 */
export async function summarize(content: string): Promise<string> {
  const response = await openai.chat.completions.create({
    model: config.OPENAI_CHAT_MODEL,
    messages: [
      {
        role: "system",
        content:
          "You are a concise summarizer. Produce a brief summary of the following content in 2-3 sentences.",
      },
      { role: "user", content },
    ],
    max_tokens: 200,
  });
  return response.choices[0].message.content ?? "";
}

/**
 * Explain the connection between two pieces of content.
 */
export async function explainConnection(
  contentA: string,
  contentB: string,
): Promise<string> {
  const response = await openai.chat.completions.create({
    model: config.OPENAI_CHAT_MODEL,
    messages: [
      {
        role: "system",
        content:
          "You are a knowledge analyst. Explain in 1-2 sentences how the following two pieces of information are related.",
      },
      {
        role: "user",
        content: `Content A:\n${contentA}\n\nContent B:\n${contentB}`,
      },
    ],
    max_tokens: 150,
  });
  return response.choices[0].message.content ?? "";
}

/**
 * Suggest further reading or research directions based on a fragment.
 */
export async function suggestResources(content: string): Promise<string[]> {
  const response = await openai.chat.completions.create({
    model: config.OPENAI_CHAT_MODEL,
    messages: [
      {
        role: "system",
        content:
          "Based on the following content, suggest 3-5 related topics, search queries, or areas for further reading. Return each suggestion on a new line.",
      },
      { role: "user", content },
    ],
    max_tokens: 300,
  });
  const text = response.choices[0].message.content ?? "";
  return text
    .split("\n")
    .map((s) => s.replace(/^\d+\.\s*/, "").trim())
    .filter(Boolean);
}
