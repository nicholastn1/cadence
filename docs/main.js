// Cadence landing page: translations, the live notch demo, the scroll stage, themes.

// Fill these in to show the support buttons (both stay hidden while empty).
const SUPPORT = { kofi: "", githubSponsors: "" };

const STRINGS = {
  en: {
    "nav.theme": "Switch between light and dark",
    "hero.title": "Read your script without looking away.",
    "hero.sub": "Cadence puts your lines in your MacBook's notch, right under the camera, and scrolls at the pace you speak.",
    "hero.copy": "Copy", "hero.copied": "Copied",
    "hero.download": "Download the app",
    "hero.req": "Free and open source. Apple Silicon, macOS 14 or later.",
    "hero.note": "Not signed by Apple yet. If you download the app, the first time you open it go to System Settings > Privacy & Security and click Open Anyway. Homebrew skips this step.",
    "demo.controls": "Demo controls",
    "demo.restart": "Back to the top", "demo.play": "Play", "demo.pause": "Pause",
    "demo.listen": "Read aloud", "demo.stop": "Stop listening",
    "demo.edit": "Edit text", "demo.apply": "Use this text", "demo.cancel": "Cancel",
    "demo.placeholder": "Paste a few lines you'd say on a call.",
    "demo.idle": "Press Read aloud and read the lines in the notch.",
    "demo.listening": "Listening. Read the lines in the notch.",
    "demo.offscript": "Off script. Waiting for you.",
    "demo.noapi": "This browser can't listen. Try Chrome or Safari, or press Play.",
    "demo.denied": "Microphone access is off for this page. Allow it in your browser's site settings, or press Play.",
    "demo.done": "That's the end. Press Back to the top to go again.",
    "demo.privacy": "In this demo, your browser's speech service does the listening. The Mac app listens on your Mac.",
    "demo.onair": "You're on air",
    "demo.script": "You're reading this from the notch, right under the camera. People see you looking at them, not at your notes. Read it out loud and the text follows you. Stop, and it waits. Say something that isn't here, and it holds still until you come back.",
    "video.title": "Watch the one-minute guide", "video.play": "Play the guide", "video.note": "",
    "features.title": "What it does",
    "features.script": [
      "**Lives in the notch.** The panel springs out of the notch when you need it and tucks back in when you don't. [breathe]",
      "**Follows your voice.** It scrolls while you talk, waits when you pause, and ==holds still when you go off script==.",
      "**Hidden from screen sharing.** People on Zoom, Meet or Teams see you, not your notes. It doesn't show up in screenshots either.",
      "**Marks your place.** Words you've read fade, and the word you're on is highlighted.",
      "**Made for reading aloud.** Stress words, highlight phrases, and leave yourself notes like [smile] that are never read.",
      "**The details.** A 3-2-1 countdown, mirror mode for teleprompter glass, a script library, import from Word, Markdown and text files, pace stats after each take, and quick controls in the menu bar.",
    ],
    "voice.title": "How voice mode works",
    "voice.s1t": "It listens",
    "voice.s1": "Speech recognition turns your voice into words several times a second, on your Mac whenever macOS supports your language.",
    "voice.s2t": "It finds your place",
    "voice.s2": "Cadence takes your last few words and looks for them near the line you're on. Numbers, accents, extra words and skipped words are all fine.",
    "voice.s3t": "It moves only when they match",
    "voice.s3": "One clear word moves it a little. Bigger jumps take two or three words in a row. After a few words that don't match, it waits for you.",
    "voice.langs": "Works in 34 languages, including English, Portuguese, Spanish, French, German, Italian, Japanese and Chinese. The app itself is in English, Portuguese and Spanish.",
    "privacy.title": "Your voice stays on your Mac",
    "privacy.text": "Speech recognition runs on your Mac whenever macOS supports your language. Languages that need Apple's servers are marked, so you always know. Cadence has no accounts and no analytics, and neither does this page.",
    "faq.title": "Questions",
    "faq": [
      ["Will people on my call see it?", "No. Cadence is hidden from screen sharing and screenshots, so only you see it."],
      ["Does it work without a notch?", "Yes. On an external display or a Mac without a notch, the panel hangs from the top center of the screen."],
      ["Which Macs does it run on?", "Macs with Apple Silicon on macOS 14 Sonoma or later."],
      ["Is it really free?", "Yes. Cadence is open source under the MIT license. No accounts, no trials, no ads."],
      ["Why does macOS warn me the first time?", "Cadence isn't signed by Apple yet. Homebrew takes care of it. If you downloaded the app, open System Settings > Privacy & Security and click Open Anyway."],
      ["Does it need the internet?", "Only for languages macOS can't recognize on your Mac. Steady scrolling never needs it."],
      ["Does it work with Zoom, Meet, Teams and OBS?", "Yes. It sits on your screen, not inside any app, so it works with all of them."],
    ],
    "open.title": "Built in the open",
    "open.text": "Cadence is a small, growing project. Read the code, suggest a feature, or translate it into your language.",
    "open.code": "Source code", "open.roadmap": "Roadmap", "open.changelog": "Changelog", "open.contributing": "Contributing",
    "open.version": "Latest version: {v}",
    "support.title": "Support Cadence",
    "support.text": "Cadence is free. If it helps you, you can chip in to keep it growing.",
    "foot.text": "MIT license. Made by Nicholas Nogueira.",
  },
  pt: {
    "nav.theme": "Alternar entre claro e escuro",
    "hero.title": "Leia seu roteiro sem desviar o olhar.",
    "hero.sub": "O Cadence coloca suas falas no notch do MacBook, logo abaixo da câmera, e rola no ritmo em que você fala.",
    "hero.copy": "Copiar", "hero.copied": "Copiado",
    "hero.download": "Baixar o app",
    "hero.req": "Gratuito e open source. Apple Silicon, macOS 14 ou mais recente.",
    "hero.note": "Ainda não é assinado pela Apple. Se você baixar o app, na primeira vez que abrir vá em Ajustes do Sistema > Privacidade e Segurança e clique em Abrir Mesmo Assim. O Homebrew pula essa etapa.",
    "demo.controls": "Controles da demonstração",
    "demo.restart": "Voltar ao início", "demo.play": "Reproduzir", "demo.pause": "Pausar",
    "demo.listen": "Ler em voz alta", "demo.stop": "Parar de ouvir",
    "demo.edit": "Editar texto", "demo.apply": "Usar este texto", "demo.cancel": "Cancelar",
    "demo.placeholder": "Cole algumas falas que você diria numa chamada.",
    "demo.idle": "Clique em Ler em voz alta e leia as linhas no notch.",
    "demo.listening": "Ouvindo. Leia as linhas no notch.",
    "demo.offscript": "Fora do roteiro. Esperando você.",
    "demo.noapi": "Este navegador não consegue ouvir. Tente o Chrome ou o Safari, ou clique em Reproduzir.",
    "demo.denied": "O microfone está bloqueado nesta página. Permita nos ajustes do site no navegador, ou clique em Reproduzir.",
    "demo.done": "Fim. Clique em Voltar ao início para ler de novo.",
    "demo.privacy": "Nesta demonstração, quem ouve é o serviço de fala do seu navegador. O app para Mac ouve no próprio Mac.",
    "demo.onair": "Você está no ar",
    "demo.script": "Você está lendo isto no notch, logo abaixo da câmera. As pessoas veem você olhando para elas, não para as suas anotações. Leia em voz alta e o texto acompanha você. Pare, e ele espera. Diga algo que não está aqui, e ele fica parado até você voltar.",
    "video.title": "Assista ao guia de um minuto", "video.play": "Ver o guia", "video.note": "Vídeo em inglês.",
    "features.title": "O que ele faz",
    "features.script": [
      "**Mora no notch.** O painel sai do notch quando você precisa e volta para dentro quando não precisa. [respire]",
      "**Segue a sua voz.** Rola enquanto você fala, espera quando você pausa e ==fica parado quando você sai do roteiro==.",
      "**Invisível no compartilhamento de tela.** Quem está no Zoom, Meet ou Teams vê você, não as suas anotações. Também não aparece em capturas de tela.",
      "**Marca onde você está.** As palavras já lidas ficam apagadas e a palavra atual fica destacada.",
      "**Feito para ler em voz alta.** Dê ênfase a palavras, destaque frases e deixe notas para você, como [sorria], que nunca são lidas.",
      "**Os detalhes.** Contagem regressiva, modo espelhado para vidro de teleprompter, biblioteca de roteiros, importação de Word, Markdown e texto, estatísticas de ritmo depois de cada leitura e controles rápidos na barra de menus.",
    ],
    "voice.title": "Como o modo voz funciona",
    "voice.s1t": "Ele ouve",
    "voice.s1": "O reconhecimento de fala transforma sua voz em palavras várias vezes por segundo, no próprio Mac sempre que o macOS suporta o seu idioma.",
    "voice.s2t": "Ele acha onde você está",
    "voice.s2": "O Cadence pega suas últimas palavras e procura por elas perto da linha em que você está. Números, acentos, palavras a mais e palavras puladas não atrapalham.",
    "voice.s3t": "Ele só anda quando elas batem",
    "voice.s3": "Uma palavra clara faz andar um pouco. Saltos maiores precisam de duas ou três palavras seguidas. Depois de algumas palavras que não batem, ele espera você.",
    "voice.langs": "Funciona em 34 idiomas, incluindo português, inglês, espanhol, francês, alemão, italiano, japonês e chinês. O app em si está em português, inglês e espanhol.",
    "privacy.title": "Sua voz fica no seu Mac",
    "privacy.text": "O reconhecimento de fala roda no seu Mac sempre que o macOS suporta o seu idioma. Idiomas que precisam dos servidores da Apple são marcados, então você sempre sabe. O Cadence não tem contas nem analytics, e esta página também não.",
    "faq.title": "Perguntas",
    "faq": [
      ["As pessoas na chamada vão ver?", "Não. O Cadence fica invisível no compartilhamento de tela e nas capturas de tela, então só você vê."],
      ["Funciona sem notch?", "Sim. Num monitor externo ou num Mac sem notch, o painel fica pendurado no centro do topo da tela."],
      ["Em quais Macs funciona?", "Macs com Apple Silicon no macOS 14 Sonoma ou mais recente."],
      ["É gratuito mesmo?", "Sim. O Cadence é open source, com licença MIT. Sem contas, sem período de teste, sem anúncios."],
      ["Por que o macOS mostra um aviso na primeira vez?", "O Cadence ainda não é assinado pela Apple. O Homebrew resolve isso. Se você baixou o app, abra Ajustes do Sistema > Privacidade e Segurança e clique em Abrir Mesmo Assim."],
      ["Precisa de internet?", "Só para idiomas que o macOS não reconhece no próprio Mac. A rolagem em ritmo constante nunca precisa."],
      ["Funciona com Zoom, Meet, Teams e OBS?", "Sim. Ele fica na sua tela, não dentro de um app, então funciona com todos."],
    ],
    "open.title": "Feito às claras",
    "open.text": "O Cadence é um projeto pequeno e em crescimento. Leia o código, sugira uma funcionalidade ou traduza para o seu idioma.",
    "open.code": "Código-fonte", "open.roadmap": "Roadmap", "open.changelog": "Novidades", "open.contributing": "Como contribuir",
    "open.version": "Versão mais recente: {v}",
    "support.title": "Apoie o Cadence",
    "support.text": "O Cadence é gratuito. Se ele te ajuda, você pode contribuir para ele continuar crescendo.",
    "foot.text": "Licença MIT. Feito por Nicholas Nogueira.",
  },
  es: {
    "nav.theme": "Cambiar entre claro y oscuro",
    "hero.title": "Lee tu guion sin apartar la mirada.",
    "hero.sub": "Cadence pone tus líneas en el notch de tu MacBook, justo debajo de la cámara, y avanza al ritmo en que hablas.",
    "hero.copy": "Copiar", "hero.copied": "Copiado",
    "hero.download": "Descargar la app",
    "hero.req": "Gratis y de código abierto. Apple Silicon, macOS 14 o posterior.",
    "hero.note": "Todavía no está firmada por Apple. Si descargas la app, la primera vez que la abras ve a Ajustes del Sistema > Privacidad y Seguridad y haz clic en Abrir de todos modos. Homebrew se salta este paso.",
    "demo.controls": "Controles de la demostración",
    "demo.restart": "Volver al inicio", "demo.play": "Reproducir", "demo.pause": "Pausar",
    "demo.listen": "Leer en voz alta", "demo.stop": "Dejar de escuchar",
    "demo.edit": "Editar texto", "demo.apply": "Usar este texto", "demo.cancel": "Cancelar",
    "demo.placeholder": "Pega algunas líneas que dirías en una llamada.",
    "demo.idle": "Pulsa Leer en voz alta y lee las líneas del notch.",
    "demo.listening": "Escuchando. Lee las líneas del notch.",
    "demo.offscript": "Fuera del guion. Esperándote.",
    "demo.noapi": "Este navegador no puede escuchar. Prueba Chrome o Safari, o pulsa Reproducir.",
    "demo.denied": "El micrófono está bloqueado en esta página. Permítelo en los ajustes del sitio de tu navegador, o pulsa Reproducir.",
    "demo.done": "Fin. Pulsa Volver al inicio para leer otra vez.",
    "demo.privacy": "En esta demostración escucha el servicio de voz de tu navegador. La app para Mac escucha en tu Mac.",
    "demo.onair": "Estás en el aire",
    "demo.script": "Estás leyendo esto desde el notch, justo debajo de la cámara. La gente te ve mirándolos a ellos, no a tus notas. Léelo en voz alta y el texto te sigue. Detente, y espera. Di algo que no está aquí, y se queda quieto hasta que vuelvas.",
    "video.title": "Mira la guía de un minuto", "video.play": "Ver la guía", "video.note": "Vídeo en inglés.",
    "features.title": "Qué hace",
    "features.script": [
      "**Vive en el notch.** El panel sale del notch cuando lo necesitas y vuelve a esconderse cuando no. [respira]",
      "**Sigue tu voz.** Avanza mientras hablas, espera cuando haces una pausa y ==se queda quieto cuando te sales del guion==.",
      "**Invisible al compartir pantalla.** Quien está en Zoom, Meet o Teams te ve a ti, no tus notas. Tampoco aparece en capturas de pantalla.",
      "**Marca por dónde vas.** Las palabras ya leídas se atenúan y la palabra actual queda resaltada.",
      "**Hecho para leer en voz alta.** Da énfasis a palabras, resalta frases y déjate notas como [sonríe] que nunca se leen.",
      "**Los detalles.** Cuenta atrás, modo espejo para cristal de teleprompter, biblioteca de guiones, importación de Word, Markdown y texto, estadísticas de ritmo después de cada toma y controles rápidos en la barra de menús.",
    ],
    "voice.title": "Cómo funciona el modo voz",
    "voice.s1t": "Escucha",
    "voice.s1": "El reconocimiento de voz convierte tu voz en palabras varias veces por segundo, en tu Mac siempre que macOS admita tu idioma.",
    "voice.s2t": "Encuentra por dónde vas",
    "voice.s2": "Cadence toma tus últimas palabras y las busca cerca de la línea en la que estás. Números, acentos, palabras de más y palabras saltadas no son problema.",
    "voice.s3t": "Solo avanza cuando coinciden",
    "voice.s3": "Una palabra clara lo mueve un poco. Los saltos grandes necesitan dos o tres palabras seguidas. Después de unas palabras que no coinciden, te espera.",
    "voice.langs": "Funciona en 34 idiomas, entre ellos español, inglés, portugués, francés, alemán, italiano, japonés y chino. La app está en español, inglés y portugués.",
    "privacy.title": "Tu voz se queda en tu Mac",
    "privacy.text": "El reconocimiento de voz funciona en tu Mac siempre que macOS admita tu idioma. Los idiomas que necesitan los servidores de Apple están marcados, así que siempre lo sabes. Cadence no tiene cuentas ni analíticas, y esta página tampoco.",
    "faq.title": "Preguntas",
    "faq": [
      ["¿Lo verá la gente en mi llamada?", "No. Cadence es invisible al compartir pantalla y en las capturas, así que solo lo ves tú."],
      ["¿Funciona sin notch?", "Sí. En un monitor externo o en un Mac sin notch, el panel cuelga del centro superior de la pantalla."],
      ["¿En qué Macs funciona?", "Macs con Apple Silicon y macOS 14 Sonoma o posterior."],
      ["¿De verdad es gratis?", "Sí. Cadence es de código abierto con licencia MIT. Sin cuentas, sin pruebas, sin anuncios."],
      ["¿Por qué macOS me avisa la primera vez?", "Cadence todavía no está firmada por Apple. Homebrew se encarga de eso. Si descargaste la app, abre Ajustes del Sistema > Privacidad y Seguridad y haz clic en Abrir de todos modos."],
      ["¿Necesita internet?", "Solo para idiomas que macOS no reconoce en tu Mac. El desplazamiento a ritmo constante nunca lo necesita."],
      ["¿Funciona con Zoom, Meet, Teams y OBS?", "Sí. Está en tu pantalla, no dentro de una app, así que funciona con todos."],
    ],
    "open.title": "Hecho a la vista",
    "open.text": "Cadence es un proyecto pequeño y en crecimiento. Lee el código, sugiere una función o tradúcelo a tu idioma.",
    "open.code": "Código fuente", "open.roadmap": "Hoja de ruta", "open.changelog": "Novedades", "open.contributing": "Cómo contribuir",
    "open.version": "Última versión: {v}",
    "support.title": "Apoya Cadence",
    "support.text": "Cadence es gratis. Si te ayuda, puedes aportar para que siga creciendo.",
    "foot.text": "Licencia MIT. Hecho por Nicholas Nogueira.",
  },
};

const $ = (id) => document.getElementById(id);
const root = document.documentElement;
const reduced = matchMedia("(prefers-reduced-motion: reduce)");
let lang = "en";
const t = (k) => STRINGS[lang][k] ?? STRINGS.en[k];

/* ---------- Language ---------- */

function pickLang() {
  const q = new URLSearchParams(location.search).get("lang");
  if (q && STRINGS[q]) return q;
  for (const l of navigator.languages || [navigator.language]) {
    const code = l.slice(0, 2).toLowerCase();
    if (STRINGS[code]) return code;
  }
  return "en";
}

function escapeHTML(s) { return s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]); }

// Script markup for the "What it does" section, with the marks left visible like in the app's editor.
function markup(s) {
  return escapeHTML(s)
    .replace(/\*\*(.+?)\*\*/g, '<span class="mk">**</span><strong>$1</strong><span class="mk">**</span>')
    .replace(/==(.+?)==/g, '<span class="mk">==</span><mark>$1</mark><span class="mk">==</span>')
    .replace(/\[(.+?)\]/g, '<span class="cue">[$1]</span>');
}

function applyLang(next, push) {
  lang = next;
  root.lang = { en: "en", pt: "pt-BR", es: "es" }[lang];
  document.querySelectorAll("[data-i18n]").forEach((el) => { el.textContent = t(el.dataset.i18n); });
  document.querySelectorAll("[data-i18n-label]").forEach((el) => { el.setAttribute("aria-label", t(el.dataset.i18nLabel)); el.title = t(el.dataset.i18nLabel); });
  document.querySelectorAll("[data-i18n-placeholder]").forEach((el) => { el.placeholder = t(el.dataset.i18nPlaceholder); });
  document.querySelectorAll(".langs button").forEach((b) => b.setAttribute("aria-pressed", String(b.dataset.lang === lang)));
  $("featureScript").innerHTML = t("features.script").map((p) => `<p>${markup(p)}</p>`).join("");
  $("faq").innerHTML = t("faq").map(([q, a]) => `<details><summary>${escapeHTML(q)}</summary><p>${escapeHTML(a)}</p></details>`).join("");
  if (latest) $("version").textContent = t("open.version").replace("{v}", latest);
  if (push) {
    const url = new URL(location.href);
    url.searchParams.set("lang", lang);
    history.replaceState(null, "", url);
  }
  demo.load(customText || t("demo.script"));
  renderSupport();
}

document.querySelectorAll(".langs button").forEach((b) => b.addEventListener("click", () => applyLang(b.dataset.lang, true)));

/* ---------- Theme: system by default, a toggle, and the red easter egg ---------- */

const darkQuery = matchMedia("(prefers-color-scheme: dark)");
function syncDark() {
  const explicit = root.dataset.theme;
  const dark = explicit ? explicit === "dark" : darkQuery.matches;
  root.toggleAttribute("data-dark", dark);
}
try { const saved = localStorage.getItem("theme"); if (saved) root.dataset.theme = saved; } catch {}
syncDark();
darkQuery.addEventListener("change", syncDark);
$("theme").addEventListener("click", () => {
  const next = root.hasAttribute("data-dark") ? "light" : "dark";
  root.dataset.theme = next;
  try { localStorage.setItem("theme", next); } catch {}
  syncDark();
});

// Hidden: click the camera in the notch and the page goes on air. Not remembered on reload.
$("camera").addEventListener("click", () => {
  const on = !root.hasAttribute("data-red");
  root.toggleAttribute("data-red", on);
  if (on) {
    $("island").classList.add("on-air");
    setTimeout(() => $("island").classList.remove("on-air"), 1800);
  }
});

/* ---------- Install ---------- */

$("copy").addEventListener("click", async () => {
  try { await navigator.clipboard.writeText($("brew").textContent); } catch { return; }
  $("copy").textContent = t("hero.copied");
  setTimeout(() => { $("copy").textContent = t("hero.copy"); }, 1600);
});

let latest = "";
fetch("https://api.github.com/repos/nicholastn1/cadence/releases/latest")
  .then((r) => (r.ok ? r.json() : null))
  .then((r) => {
    if (!r) return;
    latest = r.tag_name.replace(/^v/, "");
    $("version").textContent = t("open.version").replace("{v}", latest);
    const zip = (r.assets || []).find((a) => a.name.endsWith(".zip"));
    if (zip) $("download").href = zip.browser_download_url;
  })
  .catch(() => {});

function renderSupport() {
  const links = [];
  if (SUPPORT.githubSponsors) links.push(`<a href="https://github.com/sponsors/${SUPPORT.githubSponsors}">GitHub Sponsors</a>`);
  if (SUPPORT.kofi) links.push(`<a href="https://ko-fi.com/${SUPPORT.kofi}">Ko-fi</a>`);
  $("support").hidden = links.length === 0;
  $("supportLinks").innerHTML = links.join(" ");
}

/* ---------- The demo: a small port of the app's matching ---------- */

const norm = (w) => w.normalize("NFD").replace(/\p{M}/gu, "").toLowerCase();
const wordsOf = (s) => (s.match(/[\p{L}\p{N}']+/gu) || []).map(norm);
const substantial = (w) => w.length >= (/^[\x00-\x7f]+$/.test(w) ? 4 : 2);

function similar(a, b) {
  if (a === b) return true;
  if (Math.min(a.length, b.length) < 5 || Math.abs(a.length - b.length) > 1) return false;
  let prev = Array.from({ length: b.length + 1 }, (_, j) => j);
  for (let i = 1; i <= a.length; i++) {
    const cur = [i];
    for (let j = 1; j <= b.length; j++) cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
    prev = cur;
  }
  return prev[b.length] <= 1;
}

function locate(heard, words, cursor, strict) {
  const tail = heard.slice(-6);
  if (!tail.length || !words.length) return null;
  const lo = Math.max(0, cursor - 4), hi = Math.min(words.length - 1, cursor + 60);
  let best = null;
  for (let i = lo; i <= hi; i++) {
    if (!tail.slice(-2).some((h) => similar(h, words[i]))) continue;
    let k = i, score = 0;
    for (const h of [...tail].reverse()) {
      if (k < 0) break;
      for (let m = k; m >= Math.max(0, k - 2); m--) if (similar(h, words[m])) { score++; k = m - 1; break; }
    }
    const step = i - cursor;
    const needed = strict ? 3 : step >= 0 && step <= 2 ? 1 : step >= 0 && step <= 8 ? 2 : 3;
    if (score < needed || (score === 1 && !substantial(words[i]))) continue;
    if (!best || score > best.score || (score === best.score && Math.abs(step) < Math.abs(best.i - cursor))) best = { score, i };
  }
  return best ? best.i : null;
}

const demo = {
  words: [], spans: [], cursor: -1, offset: 0, playing: false, listening: false,
  rec: null, unmatched: 0, heardCount: 0, raf: 0, last: 0,

  load(text) {
    this.stopAll();
    const lines = $("lines");
    lines.innerHTML = "";
    this.spans = [];
    this.words = [];
    for (const part of text.split(/(\s+)/)) {
      if (!part) continue;
      if (/^\s+$/.test(part)) { lines.append(part); continue; }
      const span = document.createElement("span");
      span.className = "w";
      span.textContent = part;
      lines.append(span);
      for (const w of wordsOf(part)) { this.words.push(w); this.spans.push(span); }
    }
    this.restart();
  },

  restart() {
    this.cursor = -1; this.offset = 0; this.unmatched = 0;
    this.spans.forEach((s) => s.classList.remove("read", "now"));
    this.apply();
    status(this.listening ? "demo.listening" : "demo.idle");
  },

  apply() { $("lines").style.transform = `translateY(${-this.offset}px)`; },
  maxOffset() { return Math.max(0, $("lines").scrollHeight - $("islandText").clientHeight + 20); },

  // Steady scroll, with the app's 3-2-1.
  async play() {
    if (this.playing) return this.pause();
    this.stopListening();
    if (this.offset >= this.maxOffset()) this.restart();
    this.playing = true;
    $("demoLayer").classList.add("playing");
    setLabel($("play"), "demo.pause");
    if (!reduced.matches) {
      const island = $("island");
      island.classList.add("counting");
      for (const n of [3, 2, 1]) {
        $("count").textContent = n;
        await sleep(800);
        if (!this.playing) { island.classList.remove("counting"); return; }
      }
      island.classList.remove("counting");
    }
    this.last = performance.now();
    const step = (now) => {
      if (!this.playing) return;
      this.offset = Math.min(this.maxOffset(), this.offset + ((now - this.last) / 1000) * 26);
      this.last = now;
      this.apply();
      if (this.offset >= this.maxOffset()) { this.pause(); status("demo.done"); return; }
      this.raf = requestAnimationFrame(step);
    };
    this.raf = requestAnimationFrame(step);
  },

  pause() {
    this.playing = false;
    cancelAnimationFrame(this.raf);
    $("demoLayer").classList.remove("playing");
    $("island").classList.remove("counting");
    setLabel($("play"), "demo.play");
  },

  // Voice: the browser's speech recognition feeds the same matching rules as the app.
  listen() {
    if (this.listening) return this.stopListening();
    const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SR) return status("demo.noapi");
    this.pause();
    const rec = new SR();
    rec.lang = { en: "en-US", pt: "pt-BR", es: "es-ES" }[lang];
    rec.continuous = true;
    rec.interimResults = true;
    rec.onresult = (e) => {
      let text = "";
      for (let i = 0; i < e.results.length; i++) text += e.results[i][0].transcript + " ";
      this.heard(wordsOf(text));
    };
    rec.onerror = (e) => {
      if (e.error === "not-allowed" || e.error === "service-not-allowed") { this.stopListening(); status("demo.denied"); }
    };
    rec.onend = () => { if (this.listening) { this.heardCount = 0; try { rec.start(); } catch {} } }; // sessions end on silence
    this.rec = rec;
    this.listening = true;
    this.heardCount = 0;
    $("listen").setAttribute("aria-pressed", "true");
    $("listenLabel").textContent = t("demo.stop");
    status("demo.listening");
    try { rec.start(); } catch { this.stopListening(); status("demo.noapi"); }
  },

  heard(heard) {
    const fresh = Math.max(0, heard.length - this.heardCount);
    this.heardCount = heard.length;
    const i = locate(heard, this.words, Math.max(0, this.cursor), this.unmatched >= 6);
    if (i === null) {
      this.unmatched += fresh;
      if (this.unmatched >= 6) status("demo.offscript");
      return;
    }
    this.unmatched = 0;
    status("demo.listening");
    if (i < this.cursor) this.spans.forEach((s) => s.classList.remove("read"));
    this.cursor = i;
    const now = this.spans[i];
    this.spans.forEach((s, k) => { s.classList.toggle("read", k < i && s !== now); s.classList.toggle("now", s === now); });
    this.offset = Math.min(this.maxOffset(), Math.max(0, now.offsetTop - 4));
    this.apply();
    if (i === this.words.length - 1) { this.stopListening(); status("demo.done"); }
  },

  stopListening() {
    if (!this.listening) return;
    this.listening = false;
    try { this.rec && this.rec.stop(); } catch {}
    $("listen").setAttribute("aria-pressed", "false");
    $("listenLabel").textContent = t("demo.listen");
    status("demo.idle");
  },

  stopAll() { this.pause(); this.stopListening(); },
};

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
function status(key) { $("status").textContent = t(key); }
function setLabel(el, key) { el.setAttribute("aria-label", t(key)); el.title = t(key); }

$("play").addEventListener("click", () => demo.play());
$("restart").addEventListener("click", () => { demo.pause(); demo.restart(); });
$("listen").addEventListener("click", () => demo.listen());

let customText = "";
function setEditing(on) {
  $("editor").hidden = !on;
  root.classList.toggle("editing", on);
  layoutStage();
}
$("edit").addEventListener("click", () => {
  setEditing($("editor").hidden);
  if (!$("editor").hidden) { $("editorText").value = customText; $("editorText").focus(); }
});
$("editCancel").addEventListener("click", () => { setEditing(false); $("edit").focus(); });
$("editor").addEventListener("keydown", (e) => { if (e.key === "Escape") { setEditing(false); $("edit").focus(); } });
$("editor").addEventListener("submit", (e) => {
  e.preventDefault();
  customText = $("editorText").value.trim();
  setEditing(false);
  demo.load(customText || t("demo.script"));
});

/* ---------- The stage: hero close-up pulls back to the whole laptop ---------- */

const stage = $("stage"), laptop = $("laptop");
const ease = (x) => (x < 0.5 ? 2 * x * x : 1 - Math.pow(-2 * x + 2, 2) / 2);
const clamp01 = (x) => Math.min(1, Math.max(0, x));
const range = (p, a, b) => clamp01((p - a) / (b - a));
let isStatic = false;

function layoutStage() {
  const vw = innerWidth, vh = innerHeight;
  isStatic = vw < 820 || reduced.matches;
  root.classList.toggle("static", isStatic);
  if (isStatic) {
    // Close-up only: scale so the island reads on a phone, crop below the controls.
    const s = Math.min(1, vw / 620), crop = root.classList.contains("editing") ? 560 : 400; // island and controls, cut below
    laptop.style.transform = `translateY(${64 - 14 * s}px) scale(${s})`;
    laptop.style.clipPath = `inset(0 0 ${1048 - crop}px 0 round 0 0 28px 28px)`;
    document.querySelector(".sticky").style.paddingTop = `${Math.round(64 + crop * s + 28)}px`;
    return;
  }
  laptop.style.clipPath = "";
  document.querySelector(".sticky").style.paddingTop = "";
  const p = ease(clamp01((scrollY - stage.offsetTop) / (stage.offsetHeight - vh)));
  const s0 = Math.max(0.62, Math.min(1, (vw - 72) / 1540)); // keep the bezel corners in view
  const s1 = Math.min((0.86 * vw) / 1760, (0.74 * vh) / 1048);
  const y0 = 84, y1 = (vh - 1048 * s1) / 2 + 10;
  const s = s0 + (s1 - s0) * p, y = y0 + (y1 - y0) * p;
  laptop.style.transform = `translateY(${y}px) scale(${s})`;

  const copy = 1 - range(p, 0, 0.28);
  $("heroCopy").style.opacity = copy;
  $("heroCopy").style.transform = `translateY(${(1 - copy) * 50}px)`;
  $("heroCopy").style.visibility = copy === 0 ? "hidden" : "visible";
  $("heroFade").style.opacity = 1 - range(p, 0, 0.35);

  const swap = range(p, 0.55, 0.8);
  $("demoLayer").style.opacity = 1 - swap;
  $("demoLayer").style.visibility = swap === 1 ? "hidden" : "visible";
  const vl = $("videoLayer");
  vl.style.opacity = swap;
  vl.style.pointerEvents = swap > 0.9 ? "auto" : "none";
  $("videoCaption").style.opacity = range(p, 0.82, 1);
  if (p > 0.35) demo.stopAll();
  if (swap < 0.5 && !$("guide").paused) $("guide").pause();
}

addEventListener("scroll", () => requestAnimationFrame(layoutStage), { passive: true });
addEventListener("resize", layoutStage);
reduced.addEventListener("change", layoutStage);

$("playGuide").addEventListener("click", () => {
  const v = $("guide");
  $("videoLayer").classList.add("started");
  v.controls = true;
  v.play();
});

/* ---------- Start ---------- */

applyLang(pickLang(), false);
layoutStage();
// The one orchestrated moment: the notch springs open shortly after load.
setTimeout(() => $("island").classList.add("open"), reduced.matches ? 0 : 500);
