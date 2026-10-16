// Imagen con Nano Banana (modelos de imagen de Gemini): devuelve los bytes de
// la primera imagen que salga, o null si ningún modelo la da.

// Modelos de Gemini que devuelven imágenes con generateContent (los nombres
// cambian con el tiempo, así que se piden a Google). Flash primero.
async function imageModels(apiKey: string): Promise<string[]> {
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`,
  );
  if (!res.ok) return [];
  const data = await res.json();
  return (data?.models ?? [])
    .filter((m: any) =>
      String(m?.name ?? "").includes("image") &&
      m?.supportedGenerationMethods?.includes("generateContent")
    )
    .map((m: any) => m.name as string)
    .sort((a: string, b: string) =>
      Number(!a.includes("flash")) - Number(!b.includes("flash")) ||
      b.localeCompare(a)
    );
}

export async function geminiImage(
  apiKey: string,
  prompt: string,
): Promise<Uint8Array | null> {
  for (const model of await imageModels(apiKey)) {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/${model}:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: { responseModalities: ["TEXT", "IMAGE"] },
        }),
      },
    );
    if (!res.ok) {
      console.error(`${model}: HTTP ${res.status} ${await res.text()}`);
      continue;
    }
    const data = await res.json();
    const part = (data?.candidates?.[0]?.content?.parts ?? []).find(
      (p: any) => p?.inlineData?.data,
    );
    if (!part) continue;
    return Uint8Array.from(atob(part.inlineData.data), (c) => c.charCodeAt(0));
  }
  return null;
}
