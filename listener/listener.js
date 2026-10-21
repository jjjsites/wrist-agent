// Wrist Agent listener: the watch talks to this, this talks to tmux.
// Node 18+, no packages. Listens on 127.0.0.1 only; nginx adds HTTPS.
const http = require('node:http');
const crypto = require('node:crypto');
const { execFile } = require('node:child_process');

const PORT = Number(process.env.WRIST_PORT || 8787);
const SESSION = process.env.WRIST_SESSION || '';         // the tmux session Claude Code runs in
const KEY_HASH = process.env.WRIST_KEY_HASH || '';        // sha256 hex of the watch key
if (!/^[0-9a-f]{64}$/.test(KEY_HASH)) { console.error('set WRIST_KEY_HASH'); process.exit(1); }
if (!/^[\w-]{1,64}$/.test(SESSION)) { console.error('set WRIST_SESSION to your tmux session name'); process.exit(1); }

// `=name:` is an EXACT session match. A bare name matches by prefix, so
// "claude" would also reach a session called "claude-old".
const TARGET = `=${SESSION}:`;

const tmux = (args) => new Promise((ok, fail) =>
  execFile('tmux', args, { timeout: 5000 }, (err, out) => (err ? fail(err) : ok(out))));

function authorized(req) {
  const m = /^Bearer (wa_[A-Za-z0-9_-]{20,64})$/.exec(req.headers.authorization || '');
  if (!m) return false;
  const hash = crypto.createHash('sha256').update(m[1]).digest('hex');
  return crypto.timingSafeEqual(Buffer.from(hash), Buffer.from(KEY_HASH));
}

// Read only the bottom of the screen: older text can quote these phrases.
function mood(lines) {
  const text = lines.join('\n');
  if (/Enter to select|Esc to cancel|Do you want to/.test(text)) return 'waiting';
  if (/esc to interrupt/i.test(text)) return 'working';
  return 'idle';
}

// Screen lines worth showing on a watch: not dividers, not the status bar.
const CHROME = /^[\s─━╌│┃|╭╮╰╯]*$|^\s*[⏵⏸]|\? for shortcuts|^\s*❯\s*(Try ".*")?\s*$/;

async function state() {
  const pane = await tmux(['capture-pane', '-p', '-t', TARGET]);
  const lines = pane.split('\n').filter((l) => l.trim()).slice(-12);
  const text = lines.filter((l) => !CHROME.test(l));
  return { mood: mood(lines), tail: text.slice(-6).map((l) => l.trim().slice(0, 120)) };
}

let last = 0;
async function command(body) {
  if (Date.now() - last < 2000) throw Object.assign(new Error('too fast'), { status: 429 });
  last = Date.now();
  if (body.command === 'enter') return tmux(['send-keys', '-t', TARGET, 'Enter']);
  if (body.command === 'esc') return tmux(['send-keys', '-t', TARGET, 'Escape']);
  if (body.command === 'say') {
    // One line, no control characters, no slash commands.
    const text = String(body.text || '').replace(/[\u0000-\u001f\u007f]+/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 300);
    if (!text || text.startsWith('/')) throw Object.assign(new Error('bad text'), { status: 400 });
    await tmux(['send-keys', '-t', TARGET, '-l', '--', text]);
    return tmux(['send-keys', '-t', TARGET, 'Enter']);
  }
  throw Object.assign(new Error('unknown command'), { status: 400 });
}

const send = (res, status, data) => {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(data));
};

http.createServer((req, res) => {
  if (!authorized(req)) return send(res, 401, { error: 'bad key' });
  let raw = '';
  req.on('data', (c) => { raw += c; if (raw.length > 2048) req.destroy(); });
  req.on('end', async () => {
    try {
      if (req.method === 'GET' && req.url === '/wrist/state') return send(res, 200, await state());
      if (req.method === 'POST' && req.url === '/wrist/command') {
        await command(JSON.parse(raw || '{}'));
        return send(res, 200, { ok: true });
      }
      send(res, 404, { error: 'not found' });
    } catch (err) {
      send(res, err.status || 500, { error: err.message });
    }
  });
}).listen(PORT, '127.0.0.1', () => console.log(`wrist listener on 127.0.0.1:${PORT}, session ${SESSION}`));
