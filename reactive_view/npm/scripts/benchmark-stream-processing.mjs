import { performance } from "node:perf_hooks";

const CHUNK_SIZES = [1000, 5000, 10000];
const RUNS = Number(process.env.RUNS || 5);

function buildChunks(count) {
  return Array.from({ length: count }, (_, index) => ({
    type: index % 3 === 0 ? "json" : "text",
    chunk: `chunk-${index}`,
    data: { index, value: `value-${index}` },
  }));
}

function oldDeriveMessages(chunks) {
  return chunks
    .map((chunk) => {
      if (chunk.type === "json") return chunk.data;
      if (chunk.type === "text") return chunk.chunk;
      return undefined;
    })
    .filter((message) => message !== undefined);
}

function incrementalDeriveMessages(chunks) {
  let processedChunkCount = 0;
  const messages = [];

  for (let nextSize = 1; nextSize <= chunks.length; nextSize += 1) {
    if (nextSize < processedChunkCount) {
      processedChunkCount = 0;
      messages.length = 0;
    }

    const nextMessages = [];
    for (let i = processedChunkCount; i < nextSize; i += 1) {
      const chunk = chunks[i];
      const message =
        chunk.type === "json"
          ? chunk.data
          : chunk.type === "text"
            ? chunk.chunk
            : undefined;

      if (message !== undefined) nextMessages.push(message);
    }

    processedChunkCount = nextSize;
    if (nextMessages.length > 0) {
      messages.push(...nextMessages);
    }
  }

  return messages;
}

function buildSSEPayload(count) {
  return Array.from({ length: count }, (_, index) => {
    return `data: ${JSON.stringify({ type: "text", chunk: `part-${index}` })}\n\n`;
  }).join("");
}

function oldDrain(payload, sliceSize = 128) {
  let buffer = "";
  let parsed = 0;

  for (let i = 0; i < payload.length; i += sliceSize) {
    buffer += payload.slice(i, i + sliceSize);
    const events = buffer.split("\n\n");
    buffer = events.pop() || "";

    for (const event of events) {
      if (event.includes("data:")) parsed += 1;
    }
  }

  if (buffer.includes("data:")) parsed += 1;
  return parsed;
}

function newDrain(payload, sliceSize = 128) {
  let buffer = "";
  let parsed = 0;

  for (let i = 0; i < payload.length; i += sliceSize) {
    buffer += payload.slice(i, i + sliceSize);
    let separatorIndex = buffer.indexOf("\n\n");

    while (separatorIndex !== -1) {
      const event = buffer.slice(0, separatorIndex);
      if (event.includes("data:")) parsed += 1;
      buffer = buffer.slice(separatorIndex + 2);
      separatorIndex = buffer.indexOf("\n\n");
    }
  }

  if (buffer.includes("data:")) parsed += 1;
  return parsed;
}

function measure(fn) {
  const start = performance.now();
  fn();
  return performance.now() - start;
}

console.log(`stream processing benchmark (runs=${RUNS})`);

for (const chunkSize of CHUNK_SIZES) {
  const chunks = buildChunks(chunkSize);
  const payload = buildSSEPayload(chunkSize);

  let oldMessageTotal = 0;
  let newMessageTotal = 0;
  let oldDrainTotal = 0;
  let newDrainTotal = 0;

  for (let run = 0; run < RUNS; run += 1) {
    oldMessageTotal += measure(() => {
      for (let i = 1; i <= chunks.length; i += 1) oldDeriveMessages(chunks.slice(0, i));
    });
    newMessageTotal += measure(() => incrementalDeriveMessages(chunks));
    oldDrainTotal += measure(() => oldDrain(payload));
    newDrainTotal += measure(() => newDrain(payload));
  }

  const oldMessagesAvg = oldMessageTotal / RUNS;
  const newMessagesAvg = newMessageTotal / RUNS;
  const oldDrainAvg = oldDrainTotal / RUNS;
  const newDrainAvg = newDrainTotal / RUNS;

  console.log(`\nchunks=${chunkSize}`);
  console.log(
    `  message derivation old=${oldMessagesAvg.toFixed(2)}ms new=${newMessagesAvg.toFixed(2)}ms speedup=${(oldMessagesAvg / newMessagesAvg).toFixed(2)}x`
  );
  console.log(
    `  SSE draining      old=${oldDrainAvg.toFixed(2)}ms new=${newDrainAvg.toFixed(2)}ms speedup=${(oldDrainAvg / newDrainAvg).toFixed(2)}x`
  );
}
