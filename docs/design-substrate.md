# Sustrato técnico para el design system

Documento invariante: describe las restricciones del stack sobre el que corre esta
aplicación. No contiene decisiones de marca ni nada que completar.

Se pega tal cual al crear el **design system** de la app en Claude Design, junto con
el repo de la app ya conectado. La marca va en un documento aparte (ver
`brand-brief-template.md`).

Solo cambia cuando cambia el stack: un upgrade mayor de DaisyUI o Tailwind, un gate
nuevo en CI, una restricción de seguridad distinta.

---

## 1. El stack

- Tailwind CSS v4 + DaisyUI 5, ambos vendorizados en el repo (sin npm, sin Node)
- Propshaft + Importmap para assets y JavaScript (sin build step de JS)
- Hotwire (Turbo + Stimulus) para toda la interactividad
- Lucide para iconos, como SVG inline
- Lexxy como editor de rich text (Action Text)
- Content Security Policy activa y estricta: `script-src 'self'` con nonce por request
- UI bilingüe: español por defecto, inglés como fallback, todo el texto vía i18n

## 2. La regla central: el design system ES un tema DaisyUI

DaisyUI 5 ya provee la capa de tokens semánticos. No armes un sistema de tokens
paralelo ni renombres nada.

El entregable de color y forma es un tema DaisyUI válido, usando exactamente estos
nombres de variable:

**Colores** (cada uno con su par `-content` para el texto que va encima):

    --color-primary / --color-primary-content
    --color-secondary / --color-secondary-content
    --color-accent / --color-accent-content
    --color-neutral / --color-neutral-content
    --color-base-100, --color-base-200, --color-base-300, --color-base-content
    --color-info / --color-info-content
    --color-success / --color-success-content
    --color-warning / --color-warning-content
    --color-error / --color-error-content

**Forma y densidad:**

    --radius-selector, --radius-field, --radius-box
    --size-selector, --size-field
    --border, --depth, --noise

Hacen falta dos temas completos: uno claro (default) y uno oscuro. Formato esperado,
listo para pegar en `app/assets/tailwind/application.css` (el path del plugin es
local porque DaisyUI está vendorizado):

    @plugin "./daisyui-theme.mjs" {
      name: "<nombre>";
      default: true;
      --color-primary: oklch(...);
      ...
    }

## 3. Reglas de markup no negociables

1. **Color siempre por rol semántico, nunca por valor.** Se escribe `bg-base-100`,
   `text-base-content`, `btn-primary`, `alert-error`. Nunca `bg-[#1e3a8a]`,
   `text-blue-600`, ni un hex en el markup. Motivo: así el modo claro/oscuro y
   cualquier rebrand futuro salen gratis.
2. **Cero estilos inline.** Nada de `style="..."` en ningún elemento, nunca.
3. **Componente DaisyUI antes que CSS propio.** Usar las clases que ya existen:
   `btn`, `card`, `navbar`, `menu`, `dropdown`, `modal`, `drawer`, `tabs`, `table`,
   `input`, `select`, `checkbox`, `toggle`, `badge`, `alert`, `stat`, `avatar`,
   `steps`, `loading`, `skeleton`, `tooltip`, `breadcrumbs`, `join`, `chat`.
   CSS a medida solo si DaisyUI no tiene el componente, y aun así construido con los
   tokens de la sección 2.
4. **Cero dependencias externas.** La CSP bloquea todo lo que no sea same-origin: sin
   CDNs, sin Google Fonts por link, sin Font Awesome, sin imágenes remotas. Si el
   diseño necesita una tipografía, tiene que poder auto-hospedarse; si no, usar un
   system font stack.
5. **Cero JavaScript de terceros.** No proponer nada que dependa de GSAP, Framer
   Motion, Alpine, React o similares. La interactividad disponible es: CSS puro, los
   componentes DaisyUI que funcionan sin JS (modal con `<dialog>`, dropdown con
   `tabindex`, drawer con checkbox), Turbo, y controladores Stimulus simples.
6. **Iconos: solo Lucide, por nombre.** Indicar el nombre exacto del icono
   (`paperclip`, `bell`, `trash-2`). Sin emojis usados como iconos.

## 4. Restricciones que suelen olvidarse

- **Bilingüe.** Todos los textos son variables y el español ocupa alrededor de un 25 a
  30 % más que el inglés. El layout no puede depender de anchos fijos calculados sobre
  copy en inglés, ni romperse cuando un botón pasa de "Save" a "Guardar cambios".
  Nada de texto dentro de imágenes o SVG.
- **Accesibilidad.** Contraste AA como mínimo en cada par color/`-content`, foco
  visible en todo lo interactivo, labels asociados a cada input, HTML semántico
  (`<nav>`, `<main>`, `<dialog>`, `<form>`). Esto se verifica automáticamente en cada
  test de sistema: una violación WCAG 2.1 AA rompe el build. Y no se cumple sola por
  usar tokens semánticos — el tema por defecto de DaisyUI 5 no llega a AA en
  primary/primary-content (4.12:1 medidos, se exigen 4.5:1). Verificá cada par.
- **Responsive mobile-first**, con los breakpoints de Tailwind (sm/md/lg/xl).
- **Convivencia con Lexxy.** El editor de rich text trae su propio CSS y renderiza un
  `<lexxy-editor>`. El sistema tiene que armonizar con él, no pelearse.

## 5. Pantallas base

Estas vistas ya existen y funcionan en cualquier app construida sobre este stack. El
design system tiene que servirlas desde el primer día, no solo a las pantallas nuevas.

- Autenticación: iniciar sesión, registro, confirmación de email, recuperar clave
- Perfil: edición, avatar, y una zona de peligro para el borrado de cuenta
- Chat con IA: lista de conversaciones e hilo de mensajes con respuesta en streaming
- Documentos: listado, detalle con rich text, búsqueda semántica
- Blog público: índice con filtros por categoría y tag, y detalle de artículo
- Notificaciones: campana en el navbar con contador, y listado completo
- Feedback: formulario con adjuntar fotos
- Widget de soporte flotante: botón fijo más panel de chat
- Transversales: navbar con dropdown de usuario y avatar, mensajes flash, diálogo de
  confirmación, estados vacíos, estados de carga, errores de formulario

Si la app borró alguna de estas funcionalidades, se borra también de esta lista antes
de pegar el documento. Diseñar una pantalla que no existe es gastar iteraciones.

**No hace falta diseñar los paneles de administración** (madmin, dashboard de jobs,
errores, logs): son engines de terceros con su propia UI y no se estilan.

## 6. Entregables esperados

1. Los dos bloques de tema DaisyUI, claro y oscuro, completos y pegables.
2. Un mapa patrón → componente: para cada patrón de la app, qué clase DaisyUI se usa y
   con qué modificadores.
3. Escala tipográfica y de espaciado expresadas como clases Tailwind (`text-sm`,
   `gap-4`, `p-6`), no como valores en píxeles sueltos.
4. Artboards de las pantallas de la sección 5 más las propias de la app.
5. Reglas de uso escritas: cuándo primary, secondary o accent; cuándo card y cuándo
   contenido plano; qué densidad usa la app; cómo se ven los estados de hover, foco,
   deshabilitado, carga, error y vacío.

## 7. Qué no sirve

- Componentes en React, Vue o Svelte, ni JSX de ningún tipo.
- Un sistema de tokens con nombres propios que después haya que mapear a DaisyUI.
- CSS a medida que reimplemente lo que DaisyUI ya resuelve.
- Assets generados (ilustraciones, texturas, imágenes) como parte estructural del
  layout. Decorativos y opcionales está bien; estructurales no.
