// ignore_for_file: prefer_single_quotes
const String kLogViewerHtml = r'''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Dev Log Viewer</title>
  <style>
    *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
    :root{
      --bg:#0d1117;--surface:#161b22;--surface2:#21262d;--border:#30363d;
      --text:#e6edf3;--muted:#8b949e;
      --blue:#58a6ff;--green:#3fb950;--red:#f85149;
      --orange:#ffa657;--purple:#d2a8ff;--yellow:#d29922;
      --cyan:#79c0ff;--lime:#56d364;
    }
    body{background:var(--bg);color:var(--text);font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;height:100vh;display:flex;flex-direction:column;overflow:hidden}

    /* ── Toolbar ─────────────────────────────────────────────────────────── */
    #toolbar{background:var(--surface);border-bottom:1px solid var(--border);padding:10px 16px 8px;flex-shrink:0}
    .toolbar-top{display:flex;align-items:center;gap:10px;margin-bottom:8px}
    .brand{font-size:13px;font-weight:600;white-space:nowrap;display:flex;align-items:center;gap:6px;color:var(--text)}
    .brand-icon{color:var(--blue);font-size:16px}
    #search{flex:1;background:var(--bg);border:1px solid var(--border);border-radius:6px;color:var(--text);padding:5px 10px;font-size:13px;outline:none;transition:border-color .15s;font-family:inherit}
    #search:focus{border-color:var(--blue)}
    #search::placeholder{color:var(--muted)}
    .toolbar-actions{display:flex;align-items:center;gap:8px;flex-shrink:0}
    #count-badge{font-size:11px;color:var(--muted);white-space:nowrap;min-width:72px;text-align:right}
    .tb-btn{background:transparent;border:1px solid var(--border);border-radius:6px;color:var(--muted);padding:4px 10px;font-size:11px;cursor:pointer;transition:all .15s;font-family:inherit;white-space:nowrap}
    .tb-btn:hover{border-color:var(--red);color:var(--red)}
    #status-dot{width:8px;height:8px;border-radius:50%;flex-shrink:0;transition:background .3s}
    #status-dot.connected{background:var(--green)}
    #status-dot.disconnected{background:var(--red);animation:pulse 1.2s infinite}
    #status-dot.connecting{background:var(--yellow);animation:pulse 1.2s infinite}
    @keyframes pulse{0%,100%{opacity:1}50%{opacity:.25}}

    /* ── Filters ─────────────────────────────────────────────────────────── */
    .filter-row{display:flex;align-items:center;gap:14px;flex-wrap:wrap}
    .filter-group{display:flex;align-items:center;gap:5px}
    .filter-label{font-size:10px;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;white-space:nowrap}
    .filter-btns{display:flex;gap:3px;flex-wrap:wrap}
    .fbtn{background:transparent;border:1px solid var(--border);border-radius:4px;color:var(--muted);padding:2px 7px;font-size:10px;font-weight:600;cursor:pointer;transition:all .15s;font-family:'SF Mono',Consolas,monospace;letter-spacing:.2px}
    .fbtn:hover{color:var(--text);border-color:var(--muted)}
    /* Fallback for "ALL" and for dynamically-generated tags with no dedicated
       colour below — lower specificity than the [data-tag="X"] rules, so
       those still win for tags that do have one. --tag-rgb is set per-button
       in JS (ensureTag) for generated tags; unset on ALL/level buttons, so
       they fall through to the --text/--muted defaults below. */
    .fbtn.active{
      color:rgb(var(--tag-rgb,230,237,243));
      border-color:rgb(var(--tag-rgb,139,148,158));
      background:rgba(var(--tag-rgb,139,148,158),.12);
    }
    .fbtn.active[data-tag="API"]   {color:var(--blue);border-color:var(--blue);background:rgba(88,166,255,.1)}
    .fbtn.active[data-tag="AUTH"]  {color:var(--green);border-color:var(--green);background:rgba(63,185,80,.1)}
    .fbtn.active[data-tag="NOTIF"] {color:var(--purple);border-color:var(--purple);background:rgba(210,168,255,.1)}
    .fbtn.active[data-tag="NAV"]   {color:var(--orange);border-color:var(--orange);background:rgba(255,166,87,.1)}
    .fbtn.active[data-tag="STORE"] {color:var(--cyan);border-color:var(--cyan);background:rgba(121,192,255,.1)}
    .fbtn.active[data-tag="PAY"]   {color:var(--lime);border-color:var(--lime);background:rgba(86,211,100,.1)}
    .fbtn.active[data-tag^="ERR"]  {color:var(--red);border-color:var(--red);background:rgba(248,81,73,.1)}
    .fbtn.active[data-level="all"]     {color:var(--text);border-color:var(--muted);background:rgba(139,148,158,.12)}
    .fbtn.active[data-level="info"]    {color:var(--muted);border-color:var(--muted)}
    .fbtn.active[data-level="warning"] {color:var(--yellow);border-color:var(--yellow);background:rgba(210,153,34,.1)}
    .fbtn.active[data-level="error"]   {color:var(--red);border-color:var(--red);background:rgba(248,81,73,.1)}

    /* ── Log container ───────────────────────────────────────────────────── */
    #log-container{flex:1;overflow-y:auto;padding:10px 16px}
    #log-container::-webkit-scrollbar{width:6px}
    #log-container::-webkit-scrollbar-track{background:transparent}
    #log-container::-webkit-scrollbar-thumb{background:var(--border);border-radius:3px}
    #empty-state{color:var(--muted);text-align:center;margin-top:80px;font-size:13px;line-height:1.8}
    #empty-state small{display:block;font-size:11px;opacity:.6;margin-top:4px}

    /* ── Log entry ───────────────────────────────────────────────────────── */
    .entry{border:1px solid var(--border);border-left-width:3px;border-radius:6px;margin-bottom:5px;background:var(--surface);overflow:hidden;transition:background .1s}
    .entry:hover{background:var(--surface2)}
    .entry.level-info    {border-left-color:#4d535a}
    .entry.level-warning {border-left-color:var(--yellow)}
    .entry.level-error   {border-left-color:var(--red)}
    .entry-header{display:flex;align-items:flex-start;gap:7px;padding:7px 9px;cursor:default;user-select:none}
    .entry-header.clickable{cursor:pointer}
    .chevron{color:var(--muted);font-size:9px;margin-top:3px;flex-shrink:0;transition:transform .15s;width:10px;text-align:center}
    .entry.expanded .chevron{transform:rotate(90deg)}

    /* Tag badges */
    .tag-badge{font-size:9px;font-weight:700;font-family:'SF Mono',Consolas,monospace;padding:1px 5px;border-radius:3px;flex-shrink:0;margin-top:2px;letter-spacing:.3px;white-space:nowrap}
    .tag-API   {background:rgba(88,166,255,.15);color:var(--blue)}
    .tag-AUTH  {background:rgba(63,185,80,.15);color:var(--green)}
    .tag-NOTIF {background:rgba(210,168,255,.15);color:var(--purple)}
    .tag-NAV   {background:rgba(255,166,87,.15);color:var(--orange)}
    .tag-STORE {background:rgba(121,192,255,.15);color:var(--cyan)}
    .tag-PAY   {background:rgba(86,211,100,.15);color:var(--lime)}
    .tag-ERR   {background:rgba(248,81,73,.15);color:var(--red)}
    .tag-OTHER {background:rgba(139,148,158,.12);color:var(--muted)}

    .entry-meta{display:flex;flex-direction:column;flex:1;min-width:0}
    .entry-ts{font-size:10px;color:var(--muted);font-family:'SF Mono',Consolas,monospace;margin-bottom:2px}
    .entry-msg{font-size:12px;font-family:'SF Mono',Consolas,monospace;color:var(--text);white-space:pre-wrap;word-break:break-all;line-height:1.5}
    .entry-actions{flex-shrink:0}
    .copy-btn{background:transparent;border:none;color:var(--muted);cursor:pointer;padding:2px 5px;font-size:12px;opacity:0;transition:opacity .15s;border-radius:3px}
    .entry:hover .copy-btn{opacity:1}
    .copy-btn:hover{color:var(--text);background:var(--border)}

    /* Entry body (expanded) */
    .entry-body{padding:0 9px 9px;border-top:1px solid var(--border)}
    .entry-body[hidden]{display:none}
    .body-section{margin-top:7px}
    .body-label{font-size:9px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:3px}
    pre.body-pre{font-family:'SF Mono',Consolas,monospace;font-size:11px;color:var(--text);white-space:pre-wrap;word-break:break-all;background:var(--bg);border:1px solid var(--border);border-radius:4px;padding:7px;max-height:320px;overflow-y:auto;line-height:1.6}
    pre.body-pre::-webkit-scrollbar{width:4px}
    pre.body-pre::-webkit-scrollbar-thumb{background:var(--border);border-radius:2px}

    /* JSON syntax highlighting */
    .jk{color:var(--blue)}
    .js{color:var(--lime)}
    .jn{color:var(--orange)}
    .jb{color:var(--purple)}
    .jz{color:var(--muted)}

    /* Sensitive values — masked by default, click to reveal */
    .redacted{cursor:pointer;border-bottom:1px dotted var(--muted)}
    .redacted:hover{background:rgba(255,255,255,.08)}
    .redacted.revealed{border-bottom-style:solid;border-bottom-color:var(--red)}

    /* HTTP method colours */
    .m-get   {color:var(--green);font-weight:700}
    .m-post  {color:var(--blue);font-weight:700}
    .m-put   {color:var(--orange);font-weight:700}
    .m-delete{color:var(--red);font-weight:700}
    .m-patch {color:var(--purple);font-weight:700}
    .m-other {color:var(--muted);font-weight:700}

    /* HTTP status colours */
    .s2{color:var(--green)}
    .s3{color:var(--blue)}
    .s4{color:var(--orange)}
    .s5{color:var(--red)}

    /* Search highlight — bright enough to see on dark backgrounds */
    mark{background:#b8860b;color:#fff;border-radius:3px;padding:1px 3px;font-weight:600}

    /* Pause / new-badge / duration */
    .tb-btn.active{border-color:var(--yellow);color:var(--yellow)}
    #new-badge{display:none;background:rgba(88,166,255,.15);border:1px solid var(--blue);border-radius:5px;color:var(--blue);font-size:11px;padding:3px 8px;cursor:pointer;font-family:'SF Mono',Consolas,monospace;white-space:nowrap;transition:all .15s}
    #new-badge:hover{background:rgba(88,166,255,.25)}
    .duration-ms{font-size:10px;color:var(--muted);margin-left:6px;font-family:'SF Mono',Consolas,monospace}

    /* Session separator (hot restart / app started) */
    .session-sep{display:flex;align-items:center;gap:10px;margin:10px 0;user-select:none}
    .session-sep-line{flex:1;height:1px;background:var(--border)}
    .session-sep-label{
      white-space:nowrap;font-size:10px;font-weight:600;
      font-family:'SF Mono',Consolas,monospace;
      color:var(--muted);padding:3px 10px;
      border:1px solid var(--border);border-radius:10px;
      background:var(--surface);
    }

    /* New-entry animation */
    @keyframes slideIn{from{opacity:0;transform:translateY(-6px)}to{opacity:1;transform:translateY(0)}}
    .new-entry{animation:slideIn .18s ease}
  </style>
</head>
<body>
<div id="toolbar">
  <div class="toolbar-top">
    <div class="brand"><span class="brand-icon">⬡</span> <span id="project-name">Dev Log Viewer</span></div>
    <input type="search" id="search" placeholder="Search messages, JSON keys &amp; values… (try key:value)" autocomplete="off" spellcheck="false">
    <div class="toolbar-actions">
      <span id="count-badge">0 entries</span>
      <span id="new-badge"></span>
      <button class="tb-btn" id="collapse-btn">Collapse all</button>
      <button class="tb-btn" id="pause-btn">Pause</button>
      <button class="tb-btn" id="clear-btn">Clear</button>
      <div id="status-dot" class="connecting" title="Connecting…"></div>
    </div>
  </div>
  <div class="filter-row">
    <div class="filter-group">
      <span class="filter-label">Tag</span>
      <div class="filter-btns" id="tag-filters">
        <button class="fbtn active" data-tag="ALL">ALL</button>
      </div>
    </div>
    <div class="filter-group">
      <span class="filter-label">Level</span>
      <div class="filter-btns" id="level-filters">
        <button class="fbtn active" data-level="all">ALL</button>
        <button class="fbtn" data-level="info">INFO</button>
        <button class="fbtn" data-level="warning">WARN</button>
        <button class="fbtn" data-level="error">ERROR</button>
      </div>
    </div>
  </div>
</div>

<div id="log-container">
  <div id="empty-state">
    No logs yet — start your Flutter app.
    <small>Run: <code style="font-family:monospace;color:var(--cyan)">dart run tools/log_viewer/bin/log_viewer.dart</code></small>
  </div>
  <div id="log-list"></div>
</div>

<script>
// ── State ────────────────────────────────────────────────────────────────────
const S = {
  logs: [],
  seenIds: new Set(), // dedup between history fetch and live SSE events
  selectedTags: new Set(['ALL']),
  selectedLevel: 'all',
  search: '',
  knownTags: [],
  tagColors: new Map(), // tag -> "R,G,B" for generated (tag-OTHER) tags
  paused: false,
  buffer: [],          // entries received while paused
};

// ── HTML escaping ─────────────────────────────────────────────────────────────
const esc = s => String(s)
  .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');

// ── Sensitive-field masking ────────────────────────────────────────────────────
// Values for these keys render masked by default; click to reveal, or use the
// entry's Copy button which always copies the real value (entry.body is never
// mutated — only the rendered HTML is masked).
const SENSITIVE_KEYS = new Set([
  'password','pin','token','authorization','access_token','refresh_token','client_secret','cvv',
]);
const attrEsc = s => s.replace(/"/g, '&quot;');

// ── JSON syntax highlighter ───────────────────────────────────────────────────
// Escape &, <, > only (not ") so JSON quotes survive the token regex.
function syntaxHighlight(json) {
  const safe = json.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
  let pendingSensitive = false;
  return safe.replace(
    /("(?:\\u[0-9a-fA-F]{4}|\\[^u]|[^\\"])*"(?:\s*:)?|\b(?:true|false|null)\b|-?\d+(?:\.\d+)?(?:[eE][+\-]?\d+)?)/g,
    m => {
      if (m.startsWith('"')) {
        const keyMatch = m.match(/^"(.*)"\s*:$/);
        if (keyMatch) {
          pendingSensitive = SENSITIVE_KEYS.has(keyMatch[1].toLowerCase());
          return `<span class="jk">${m}</span>`;
        }
        if (pendingSensitive) {
          pendingSensitive = false;
          const masked = '"••••••••"';
          return `<span class="js redacted" data-real="${attrEsc(m)}" data-masked="${attrEsc(masked)}">${masked}</span>`;
        }
        return `<span class="js">${m}</span>`;
      }
      const wasSensitive = pendingSensitive;
      pendingSensitive = false;
      if (m==='true'||m==='false') {
        if (wasSensitive) return `<span class="jb redacted" data-real="${attrEsc(m)}" data-masked="••••••••">••••••••</span>`;
        return `<span class="jb">${m}</span>`;
      }
      if (m==='null') return `<span class="jz">${m}</span>`;
      if (wasSensitive) return `<span class="jn redacted" data-real="${attrEsc(m)}" data-masked="••••••••">••••••••</span>`;
      return `<span class="jn">${m}</span>`;
    }
  );
}

// Parse + pretty-print a string that looks like JSON; returns highlighted HTML or null.
function prettyJson(str) {
  if (!str) return null;
  const t = str.trim();
  if (!t.startsWith('{') && !t.startsWith('[')) return null;
  try { return syntaxHighlight(JSON.stringify(JSON.parse(t), null, 2)); } catch { return null; }
}

// ── Search highlighting ───────────────────────────────────────────────────────
// Highlights every term in `terms` inside rendered HTML without touching tag
// attributes. Splits on HTML tags and only replaces inside text nodes.
function highlightTerms(html, terms) {
  const valid = (terms || []).filter(Boolean);
  if (!valid.length) return html;
  const re = new RegExp(
    valid.map(t => t.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')).join('|'), 'gi');
  return html.replace(/(<[^>]*>|[^<]+)/g, part =>
    part.startsWith('<') ? part : part.replace(re, '<mark>$&</mark>')
  );
}

// ── Recursive JSON key/value search ──────────────────────────────────────────
function searchJson(val, q) {
  if (val === null || val === undefined) return false;
  if (typeof val !== 'object') return String(val).toLowerCase().includes(q);
  return Object.entries(val).some(([k, v]) =>
    k.toLowerCase().includes(q) || searchJson(v, q)
  );
}

// Parses `key:value` search syntax, e.g. "isSettled:true" or "status: 200".
// Key and value must each be a single non-whitespace token. Returns null for
// plain free-text queries (no colon, or spaces around the key).
function parseKV(q) {
  const m = q.trim().match(/^([^\s:]+)\s*:\s*(\S+)$/);
  return m ? { key: m[1], value: m[2] } : null;
}

// Recursively looks for a JSON key (case-insensitive) whose stringified value
// matches `value` (case-insensitive). Works for strings, numbers, booleans —
// anything JSON.stringify-able — since comparison is against String(v).
function searchJsonKV(val, key, value) {
  if (val === null || typeof val !== 'object') return false;
  if (Array.isArray(val)) return val.some(v => searchJsonKV(v, key, value));
  const lk = key.toLowerCase(), lv = value.toLowerCase();
  return Object.entries(val).some(([k, v]) => {
    if (k.toLowerCase() === lk && String(v).toLowerCase() === lv) return true;
    return typeof v === 'object' && v !== null && searchJsonKV(v, key, value);
  });
}

// ── Entry enrichment (pre-parse JSON bodies for fast search) ─────────────────
function tryParseJson(str) {
  if (!str) return null;
  const t = str.trim();
  if (!t.startsWith('{') && !t.startsWith('[')) return null;
  try { return JSON.parse(t); } catch { return null; }
}

function enrichEntry(entry) {
  if (entry._enriched) return;
  entry._enriched = true;
  if (entry.tag === 'API' || entry.tag.startsWith('ERR:API')) {
    const p = parseApi(entry.message);
    entry._parsed = p;
    // Structured body field (new format) — pre-index for fast JSON search.
    if (entry.body) {
      entry._jBody  = entry.body.body  ?? null;
      entry._jData  = entry.body.data  ?? null;
      entry._jQuery = entry.body.query ?? null;
    }
  } else {
    // For any other tag, try parsing the message body (lines after the first)
    const rest = entry.message.split('\n').slice(1).join('\n').trim();
    entry._jBody = tryParseJson(rest);
  }
}

// ── Utilities ─────────────────────────────────────────────────────────────────
function fmtTime(iso) {
  const d = new Date(iso);
  const p = n => String(n).padStart(2,'0');
  return `${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}.${String(d.getMilliseconds()).padStart(3,'0')}`;
}

function tagClass(tag) {
  if (tag.startsWith('ERR')) return 'tag-ERR';
  const known = ['API','AUTH','NOTIF','NAV','STORE','PAY'];
  return known.includes(tag) ? `tag-${tag}` : 'tag-OTHER';
}

// ── Colour assignment for tags with no dedicated CSS class ───────────────────
// Deterministic hash → one of the existing accent colours, so a given tag
// always renders the same colour everywhere (badge + filter chip), without
// needing a hardcoded CSS rule per possible tag string.
const TAG_PALETTE = ['88,166,255','63,185,80','255,166,87','210,168,255','210,153,34','121,192,255','86,211,100'];

function hashTag(tag) {
  let h = 0;
  for (let i = 0; i < tag.length; i++) h = (h * 31 + tag.charCodeAt(i)) | 0;
  return Math.abs(h) % TAG_PALETTE.length;
}

// Returns an "R,G,B" string for tags rendered with the generic tag-OTHER
// class, or null for tags that already have a dedicated CSS colour.
function tagRgb(tag) {
  if (tagClass(tag) !== 'tag-OTHER') return null;
  if (!S.tagColors.has(tag)) S.tagColors.set(tag, TAG_PALETTE[hashTag(tag)]);
  return S.tagColors.get(tag);
}

function methodClass(m) {
  return ({GET:'m-get',POST:'m-post',PUT:'m-put',DELETE:'m-delete',PATCH:'m-patch'})[m] || 'm-other';
}

function statusClass(s) {
  return s>=500?'s5':s>=400?'s4':s>=300?'s3':'s2';
}

// ── API message parser ────────────────────────────────────────────────────────
// Only extracts the summary (method/url/status). Body data comes from entry.body.
function parseApi(msg) {
  const req = msg.match(/^--> (\w+) (\S+)/);
  if (req) return { kind:'req', method:req[1], url:req[2] };
  const res = msg.match(/^<-- (\d+) (\S+)(?:\s+(.+))?/);
  if (res) return { kind:'res', status:+res[1], url:res[2], meta: res[3] ?? null };
  if (msg.startsWith('CACHE ')||msg.startsWith('RETRY ')) return { kind:'meta' };
  return null;
}

// ── Copy-to-clipboard text ────────────────────────────────────────────────────
// For API entries, reconstructs a clean curl-able summary (arrow line + the
// real JSON body), instead of just the bare "--> POST url" with no body that
// entry.message alone would give you.
function buildCopyText(entry) {
  const isApi = entry.tag === 'API' || entry.tag.startsWith('ERR:API');
  if (!isApi) {
    return [entry.tag, entry.timestamp, entry.message, entry.error, entry.stackTrace]
      .filter(Boolean).join('\n');
  }

  const p = entry._parsed || parseApi(entry.message);
  const lines = [];

  if (p?.kind === 'req') {
    lines.push(`--> ${p.method} ${p.url}`);
    const sections = [];
    if (entry.body?.query) sections.push(['Query', entry.body.query]);
    if (entry.body?.body)  sections.push(['Body',  entry.body.body]);
    sections.forEach(([label, data]) => {
      if (sections.length > 1) lines.push(`${label}:`);
      lines.push(JSON.stringify(data, null, 2));
    });
  } else if (p?.kind === 'res') {
    const isErr = entry.tag.startsWith('ERR');
    lines.push(`${isErr ? 'ERR ' : ''}${p.status} <-- ${p.url}`);
    if (entry.body?.data != null) lines.push(JSON.stringify(entry.body.data, null, 2));
    if (entry.error) lines.push(entry.error);
  } else {
    lines.push(entry.message);
  }

  return lines.join('\n');
}

// ── Build a JSON body section with optional search highlighting ───────────────
// dataOrStr can be a JS object/array (structured body) or a plain string.
// `terms` is an array of strings to highlight (plain query, or [key, value]
// when the search box used key:value syntax).
function jsonSection(label, dataOrStr, terms) {
  if (dataOrStr === null || dataOrStr === undefined || dataOrStr === '') return '';
  let pretty;
  if (typeof dataOrStr === 'string') {
    pretty = prettyJson(dataOrStr); // legacy: JSON embedded in message text
    if (!pretty) {
      const content = highlightTerms(esc(dataOrStr), terms);
      return label
        ? `<div class="body-section"><div class="body-label">${label}</div><pre class="body-pre">${content}</pre></div>`
        : `<div class="body-section"><pre class="body-pre">${content}</pre></div>`;
    }
  } else {
    try { pretty = syntaxHighlight(JSON.stringify(dataOrStr, null, 2)); } catch { return ''; }
  }
  const content = highlightTerms(pretty, terms);
  return label
    ? `<div class="body-section"><div class="body-label">${label}</div><pre class="body-pre">${content}</pre></div>`
    : `<div class="body-section"><pre class="body-pre">${content}</pre></div>`;
}

// ── Render entry element ──────────────────────────────────────────────────────
function buildEntry(entry, animate) {
  // Session markers render as horizontal separators, not log rows.
  if (entry.tag === 'SESSION') {
    const el = document.createElement('div');
    el.className = `session-sep${animate ? ' new-entry' : ''}`;
    el.dataset.id = entry.id;
    el.innerHTML =
      `<div class="session-sep-line"></div>` +
      `<span class="session-sep-label">${esc(entry.message)} · ${fmtTime(entry.timestamp)}</span>` +
      `<div class="session-sep-line"></div>`;
    return el;
  }

  enrichEntry(entry);
  const q = S.search;
  // key:value syntax (e.g. "isSettled:true") highlights the key and value
  // separately instead of the literal "key:value" string, which wouldn't
  // appear anywhere in pretty-printed JSON (rendered as "key": value).
  const kv = parseKV(q);
  const hlTerms = kv ? [kv.key, kv.value] : (q ? [q] : []);

  const el = document.createElement('div');
  el.className = `entry level-${entry.level}${animate?' new-entry':''}`;
  el.dataset.id = entry.id;

  const tc = tagClass(entry.tag);
  let headerHtml = '';
  let bodyHtml = '';

  if (entry.tag === 'API' || entry.tag.startsWith('ERR:API')) {
    const p = entry._parsed || parseApi(entry.message);
    if (p?.kind === 'req') {
      headerHtml = `<span class="${methodClass(p.method)}">${esc(p.method)}</span> <span style="color:var(--cyan)">${esc(p.url)}</span>`;
      bodyHtml += jsonSection('Query', entry.body?.query ?? null, hlTerms);
      bodyHtml += jsonSection('Body',  entry.body?.body  ?? null, hlTerms);
    } else if (p?.kind === 'res') {
      const sc = statusClass(p.status);
      const metaHtml = p.meta ? ` <span class="duration-ms">${esc(p.meta)}</span>` : '';
      headerHtml = `<span class="${sc}" style="font-weight:700">${p.status}</span> <span style="color:var(--muted)">${esc(p.url)}</span>${metaHtml}`;
      bodyHtml += jsonSection('Response', entry.body?.data ?? null, hlTerms);
    } else {
      headerHtml = esc(entry.message.split('\n')[0]);
      if (entry.body?.data != null) bodyHtml += jsonSection('Response', entry.body.data, hlTerms);
    }
  } else {
    const lines = entry.message.split('\n');
    headerHtml = esc(lines[0]);
    const rest = lines.slice(1).join('\n').trim();
    bodyHtml += jsonSection('', rest, hlTerms);
  }

  if (entry.error)      bodyHtml += `<div class="body-section"><div class="body-label">Error</div><pre class="body-pre" style="color:var(--red)">${highlightTerms(esc(entry.error), hlTerms)}</pre></div>`;
  if (entry.stackTrace) bodyHtml += `<div class="body-section"><div class="body-label">Stack trace</div><pre class="body-pre" style="color:var(--muted)">${esc(entry.stackTrace)}</pre></div>`;

  // Highlight search term in the entry header
  headerHtml = highlightTerms(headerHtml, hlTerms);

  const hasBody = !!bodyHtml;
  // Auto-expand when the search match lives in the body (so the user sees it).
  // Falls back to raw-string search when JSON parse failed (e.g. Dart toString format).
  const ql = q.toLowerCase();
  const bodyHasMatch = q && hasBody && (
    (kv && (
      (entry.body    && searchJsonKV(entry.body,    kv.key, kv.value)) ||
      (entry._jBody  && searchJsonKV(entry._jBody,  kv.key, kv.value)) ||
      (entry._jData  && searchJsonKV(entry._jData,  kv.key, kv.value)) ||
      (entry._jQuery && searchJsonKV(entry._jQuery, kv.key, kv.value))
    )) ||
    (entry.body    && searchJson(entry.body,    ql)) ||
    (entry._jBody  && searchJson(entry._jBody,  ql)) ||
    (entry._jData  && searchJson(entry._jData,  ql)) ||
    (entry._jQuery && searchJson(entry._jQuery, ql)) ||
    (entry.error   && entry.error.toLowerCase().includes(ql))
  );
  const autoExpand = hasBody && !!bodyHasMatch;

  const rgb = tagRgb(entry.tag);
  const tagStyle = rgb ? ` style="color:rgb(${rgb});background:rgba(${rgb},.15)"` : '';

  el.innerHTML =
    `<div class="${hasBody ? 'entry-header clickable' : 'entry-header'}">` +
      `<span class="chevron">${hasBody ? '▶' : ''}</span>` +
      `<span class="tag-badge ${tc}"${tagStyle}>${esc(entry.tag)}</span>` +
      `<div class="entry-meta">` +
        `<span class="entry-ts">${fmtTime(entry.timestamp)}</span>` +
        `<span class="entry-msg">${headerHtml}</span>` +
      `</div>` +
      `<div class="entry-actions"><button class="copy-btn" title="Copy" data-id="${entry.id}">⎘</button></div>` +
    `</div>` +
    (hasBody ? `<div class="entry-body"${autoExpand ? '' : ' hidden'}>${bodyHtml}</div>` : '');

  if (autoExpand) el.classList.add('expanded');

  if (hasBody) {
    el.querySelector('.entry-header').addEventListener('click', () => {
      const body = el.querySelector('.entry-body');
      const open = el.classList.toggle('expanded');
      body.hidden = !open;
    });
  }

  el.querySelector('.copy-btn')?.addEventListener('click', e => {
    e.stopPropagation();
    const ent = S.logs.find(l => l.id === e.currentTarget.dataset.id);
    if (!ent) return;
    const txt = buildCopyText(ent);
    navigator.clipboard.writeText(txt).then(() => {
      const btn = e.currentTarget;
      btn.textContent = '✓';
      setTimeout(() => { btn.textContent = '⎘'; }, 1200);
    });
  });

  return el;
}

// ── Filter + match ────────────────────────────────────────────────────────────
function matches(entry) {
  if (entry.tag === 'SESSION') return true; // always show session markers
  const tagOk = S.selectedTags.has('ALL') || S.selectedTags.has(entry.tag);
  const lvlOk = S.selectedLevel === 'all' || entry.level === S.selectedLevel;
  if (!tagOk || !lvlOk) return false;
  if (!S.search) return true;
  const q = S.search.toLowerCase();

  enrichEntry(entry);

  // key:value syntax, e.g. "isSettled:true" — matches a JSON key whose
  // (stringified) value equals "true", instead of a literal substring search.
  const kv = parseKV(S.search);
  if (kv) {
    if (entry.body    && searchJsonKV(entry.body,    kv.key, kv.value)) return true;
    if (entry._jBody  && searchJsonKV(entry._jBody,  kv.key, kv.value)) return true;
    if (entry._jData  && searchJsonKV(entry._jData,  kv.key, kv.value)) return true;
    if (entry._jQuery && searchJsonKV(entry._jQuery, kv.key, kv.value)) return true;
  }

  // Surface-level text matches
  if (entry.message.toLowerCase().includes(q)) return true;
  if (entry.tag.toLowerCase().includes(q)) return true;
  if ((entry.error || '').toLowerCase().includes(q)) return true;
  if ((entry.stackTrace || '').toLowerCase().includes(q)) return true;

  // Deep JSON search — keys AND values at any nesting depth
  if (entry.body    && searchJson(entry.body,    q)) return true;
  if (entry._jBody  && searchJson(entry._jBody,  q)) return true;
  if (entry._jData  && searchJson(entry._jData,  q)) return true;
  if (entry._jQuery && searchJson(entry._jQuery, q)) return true;

  return false;
}

function rerenderAll() {
  const list = document.getElementById('log-list');
  list.innerHTML = '';
  const visible = S.logs.filter(matches);
  visible.forEach(e => list.appendChild(buildEntry(e, false)));
  updateCount(visible.length);
  syncEmpty();
}

function updateCount(visible) {
  const v = visible ?? S.logs.filter(matches).length;
  const t = S.logs.length;
  document.getElementById('count-badge').textContent =
    v === t ? `${t} entries` : `${v} / ${t} entries`;
}

function syncEmpty() {
  const hasVisible = S.logs.filter(matches).length > 0;
  document.getElementById('empty-state').style.display =
    (!S.logs.length || !hasVisible) ? 'block' : 'none';
}

// ── Tag filter management ─────────────────────────────────────────────────────
function ensureTag(tag) {
  if (tag === 'SESSION') return; // session markers don't appear in tag filters
  if (S.knownTags.includes(tag)) return;
  S.knownTags.push(tag);
  const btn = document.createElement('button');
  btn.className = 'fbtn';
  btn.dataset.tag = tag;
  btn.textContent = tag;
  const rgb = tagRgb(tag);
  if (rgb) btn.style.setProperty('--tag-rgb', rgb);
  btn.addEventListener('click', () => toggleTag(tag));
  document.getElementById('tag-filters').appendChild(btn);
}

function toggleTag(tag) {
  if (tag === 'ALL') {
    S.selectedTags = new Set(['ALL']);
  } else {
    S.selectedTags.delete('ALL');
    S.selectedTags.has(tag) ? S.selectedTags.delete(tag) : S.selectedTags.add(tag);
    if (S.selectedTags.size === 0) S.selectedTags.add('ALL');
  }
  document.querySelectorAll('#tag-filters .fbtn').forEach(b =>
    b.classList.toggle('active', S.selectedTags.has(b.dataset.tag)));
  rerenderAll();
}

function setLevel(level) {
  S.selectedLevel = level;
  document.querySelectorAll('#level-filters .fbtn').forEach(b =>
    b.classList.toggle('active', b.dataset.level === level));
  rerenderAll();
}

// ── Add entry ─────────────────────────────────────────────────────────────────
const _kMaxLogs = 500;
function addEntry(entry, prepend, animate) {
  enrichEntry(entry);
  prepend ? S.logs.unshift(entry) : S.logs.push(entry);
  if (S.logs.length > _kMaxLogs) {
    prepend ? S.logs.pop() : S.logs.shift();
  }
  ensureTag(entry.tag);
  if (!matches(entry)) { updateCount(); return; }
  const list = document.getElementById('log-list');
  const el = buildEntry(entry, animate);
  prepend ? list.insertBefore(el, list.firstChild) : list.appendChild(el);
  updateCount();
  syncEmpty();
}

// ── Load history via REST (survives browser reload) ───────────────────────────
async function loadHistory() {
  try {
    const res = await fetch('/logs');
    if (!res.ok) return;
    const logs = await res.json();
    let added = 0;
    logs.forEach(entry => {
      if (S.seenIds.has(entry.id)) return; // already arrived via live SSE
      S.seenIds.add(entry.id);
      enrichEntry(entry);
      S.logs.push(entry);
      ensureTag(entry.tag);
      added++;
    });
    if (added > 0) {
      // Sort newest-first then re-render the full list once
      S.logs.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
      if (S.logs.length > _kMaxLogs) S.logs.splice(_kMaxLogs);
      rerenderAll();
    }
  } catch {}
}

// ── SSE (live events only — history comes from GET /logs) ─────────────────────
function setStatus(s) {
  const dot = document.getElementById('status-dot');
  dot.className = s;
  dot.title = s.charAt(0).toUpperCase() + s.slice(1);
}

let sse = null;

function connect() {
  if (sse) { sse.close(); sse = null; }
  setStatus('connecting');
  sse = new EventSource('/stream');
  sse.onopen = () => {
    setStatus('connected');
    // Fetch history on every (re)connect so events missed during a
    // disconnect gap are filled in without requiring a full page reload.
    loadHistory();
  };

  sse.addEventListener('clear', () => {
    S.logs = []; S.seenIds = new Set(); S.buffer = [];
    document.getElementById('log-list').innerHTML = '';
    updateCount(0); syncEmpty(); updateNewBadge();
  });

  sse.onmessage = e => {
    try {
      const entry = JSON.parse(e.data);
      if (S.seenIds.has(entry.id)) return; // already in history fetch
      S.seenIds.add(entry.id);
      if (S.paused) {
        S.buffer.push(entry);
        updateNewBadge();
      } else {
        addEntry(entry, true, true);
      }
    } catch {}
  };

  sse.onerror = () => {
    setStatus('disconnected');
    sse.close(); sse = null;
    setTimeout(connect, 3000);
  };
}

// ── Pause / resume live entries ───────────────────────────────────────────────
function updateNewBadge() {
  const badge = document.getElementById('new-badge');
  if (S.paused && S.buffer.length > 0) {
    badge.style.display = 'inline-block';
    badge.textContent = `▲ ${S.buffer.length} new`;
  } else {
    badge.style.display = 'none';
  }
}

function flushBuffer() {
  const entries = S.buffer.splice(0);
  entries.forEach(e => addEntry(e, true, false));
  updateNewBadge();
}

function togglePause() {
  S.paused = !S.paused;
  const btn = document.getElementById('pause-btn');
  btn.textContent = S.paused ? 'Resume' : 'Pause';
  btn.classList.toggle('active', S.paused);
  if (!S.paused) flushBuffer();
}

// ── Collapse / expand all ─────────────────────────────────────────────────────
let _allCollapsed = false;
function toggleCollapseAll() {
  _allCollapsed = !_allCollapsed;
  document.querySelectorAll('.entry').forEach(el => {
    const body = el.querySelector('.entry-body');
    if (!body) return;
    if (_allCollapsed) {
      el.classList.remove('expanded');
      body.hidden = true;
    } else {
      el.classList.add('expanded');
      body.hidden = false;
    }
  });
  document.getElementById('collapse-btn').textContent = _allCollapsed ? 'Expand all' : 'Collapse all';
}

// ── Controls ──────────────────────────────────────────────────────────────────
document.getElementById('clear-btn').addEventListener('click', () => {
  fetch('/logs', { method: 'DELETE' }).catch(() => {});
  S.logs = []; S.seenIds = new Set(); S.buffer = [];
  document.getElementById('log-list').innerHTML = '';
  updateCount(0); syncEmpty(); updateNewBadge();
});

let _st;
document.getElementById('search').addEventListener('input', e => {
  S.search = e.target.value;
  clearTimeout(_st);
  _st = setTimeout(rerenderAll, 160);
});

// Click-to-reveal for masked sensitive values. Delegated to the log
// container since entries (and their .redacted spans) render dynamically.
document.getElementById('log-container').addEventListener('click', e => {
  const el = e.target.closest('.redacted');
  if (!el) return;
  e.stopPropagation();
  const revealed = el.classList.toggle('revealed');
  el.textContent = revealed ? el.dataset.real : el.dataset.masked;
});

// Wires up the static "ALL" tag button — dynamically-generated tag buttons
// get their listener from ensureTag() instead, when they're first created.
document.querySelectorAll('#tag-filters .fbtn').forEach(b =>
  b.addEventListener('click', () => toggleTag(b.dataset.tag)));

document.querySelectorAll('#level-filters .fbtn').forEach(b =>
  b.addEventListener('click', () => setLevel(b.dataset.level)));

document.getElementById('pause-btn').addEventListener('click', togglePause);
document.getElementById('collapse-btn').addEventListener('click', toggleCollapseAll);
document.getElementById('new-badge').addEventListener('click', () => {
  if (!S.paused) return;
  S.paused = false;
  const btn = document.getElementById('pause-btn');
  btn.textContent = 'Pause';
  btn.classList.remove('active');
  flushBuffer();
});

// ── Start ─────────────────────────────────────────────────────────────────────
// loadHistory() runs immediately so history shows without waiting for SSE.
// sse.onopen also calls it on every (re)connect to fill in any gap entries.
connect();
loadHistory();

// Pull project name from server and update title/brand.
(async () => {
  try {
    const { project } = await fetch('/ping').then(r => r.json());
    if (project) {
      document.getElementById('project-name').textContent = project;
      document.title = `${project} — Dev Log Viewer`;
    }
  } catch {}
})();
</script>
</body>
</html>
''';
