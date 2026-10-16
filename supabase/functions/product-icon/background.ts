// Gemini no da fondos transparentes: se pide fondo blanco y aquí se borra el
// blanco que toca el borde (relleno desde los bordes), sin tocar los blancos
// de dentro del dibujo (la clara de un huevo, la espuma...).
export function clearWhiteBackground(
  rgba: Uint8Array | Uint8ClampedArray,
  width: number,
  height: number,
  threshold = 235,
): void {
  const white = (i: number) =>
    rgba[i * 4] >= threshold && rgba[i * 4 + 1] >= threshold &&
    rgba[i * 4 + 2] >= threshold && rgba[i * 4 + 3] > 0;
  const stack: number[] = [];
  for (let x = 0; x < width; x++) stack.push(x, (height - 1) * width + x);
  for (let y = 0; y < height; y++) stack.push(y * width, y * width + width - 1);
  while (stack.length) {
    const i = stack.pop()!;
    if (!white(i)) continue;
    rgba[i * 4 + 3] = 0;
    const x = i % width;
    if (x > 0) stack.push(i - 1);
    if (x < width - 1) stack.push(i + 1);
    if (i >= width) stack.push(i - width);
    if (i < width * (height - 1)) stack.push(i + width);
  }
}
