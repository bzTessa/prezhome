// Mensajes FCM de notify-home. Los textos van como claves de strings.xml
// (title_loc_key / body_loc_key): Android los pinta en el idioma del móvil
// aunque la app esté cerrada. En `data` va lo mismo para la app abierta.

export type NotifyKind = "shopping_run" | "task_assigned";

export interface NotifyInput {
  kind: NotifyKind;
  who: string;
  task?: string;
}

/** Recorta y limpia lo que escribe la gente antes de mandarlo. */
export function clean(text: unknown, max = 80): string {
  return String(text ?? "").replace(/\s+/g, " ").trim().slice(0, max);
}

export function isKind(v: unknown): v is NotifyKind {
  return v === "shopping_run" || v === "task_assigned";
}

/** Cuerpo de messages:send (FCM HTTP v1) para un token. */
export function fcmMessage(token: string, n: NotifyInput) {
  const shopping = n.kind === "shopping_run";
  const who = clean(n.who, 40) || "?";
  const task = clean(n.task);
  return {
    message: {
      token,
      data: {
        kind: n.kind,
        who,
        task,
        open: shopping ? "shopping" : "tasks",
      },
      android: {
        priority: "high",
        notification: {
          channel_id: "household",
          title_loc_key: shopping ? "push_shopping_title" : "push_task_title",
          body_loc_key: shopping ? "push_shopping_body" : "push_task_body",
          body_loc_args: shopping ? [who] : [who, task],
          // Un aviso por tipo: si llegan dos "voy al súper", se sustituyen.
          tag: shopping ? "shopping_run" : undefined,
        },
      },
    },
  };
}
