import { assertEquals } from "jsr:@std/assert@1";
import { isPublicUrl } from "./url_guard.ts";

Deno.test("acepta webs públicas", () => {
  for (const url of [
    "https://www.tiktok.com/@a/video/1",
    "http://recetas.example.com/tarta",
    "https://8.8.8.8/x",
  ]) assertEquals(isPublicUrl(url), true, url);
});

Deno.test("rechaza direcciones internas", () => {
  for (const url of [
    "http://localhost:54321/",
    "http://127.0.0.1/",
    "http://0x7f.1/",
    "http://2130706433/",
    "http://10.0.0.5/",
    "http://172.20.1.1/",
    "http://192.168.1.1/",
    "http://169.254.169.254/latest/meta-data",
    "http://[::1]/",
    "http://[fd00::1]/",
    "http://[::ffff:127.0.0.1]/",
    "http://kong/",
    "http://db.internal/",
    "file:///etc/passwd",
  ]) assertEquals(isPublicUrl(url), false, url);
});
