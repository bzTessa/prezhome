// Mensaje del 429 por límite mensual de IA: dice cuándo se renueva el cupo.
// consume_ai_credit reinicia el contador el día 1 de cada mes (hora UTC).
const MESES = [
  "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
  "agosto", "septiembre", "octubre", "noviembre", "diciembre",
];

export function aiLimitMessage(now = new Date()): string {
  const next = MESES[(now.getUTCMonth() + 1) % 12];
  return `Has llegado al límite de este mes. Se renueva el 1 de ${next}.`;
}
