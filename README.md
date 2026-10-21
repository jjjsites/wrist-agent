# Wrist Agent

See what Claude Code on your server is doing, and answer it from a Garmin watch.

Clawd, the Claude Code mascot, lives on your watch face. He walks around when
Claude Code is **idle**, types when it is **working**, jumps under a "!" when it
is **waiting for you**, and cheers when a turn ends. Press START to send
**Enter**, **Esc**, or one of three quick phrases.

> Not an Anthropic product. Claude Code and Clawd belong to Anthropic.
> This is a community project by JJJ Sites.

## How it works

```
Garmin watch ──Bluetooth──> phone (Garmin Connect) ──HTTPS──> nginx ──> listener ──tmux──> Claude Code
```

1. **Claude Code** runs inside a `tmux` session on your VPS.
2. **The listener** (`listener/listener.js`) reads the tmux screen and types keys into it.
3. **nginx** adds HTTPS. Garmin watches send web requests over HTTPS only.
4. **The watch app** (`watch/`) asks the listener for the mood every 10 seconds.

One secret key connects the watch to the listener. The listener keeps only its hash.

## What you need

| Item | Why |
| --- | --- |
| A Linux VPS with a domain name | Claude Code and the listener run here |
| A Claude subscription | Claude Code signs in with it |
| A Garmin watch with Connect IQ | The app runs on it. Find its product id on the [compatible devices](https://developer.garmin.com/connect-iq/compatible-devices/) page (Forerunner 165 = `fr165`) |
| A phone with Garmin Connect | The watch sends its requests through the phone |
| A free Garmin developer account | You download the Connect IQ SDK with it |
| Java 17+ or Docker | The Monkey C compiler runs on Java |
| The watch USB cable | You copy the app onto the watch with it |

> **WARNING:** The listener types into Claude Code. Anyone with the watch key can
> approve a permission prompt. Keep the key secret. Keep the listener on
> `127.0.0.1` behind HTTPS. Revoke a lost key: make a new one and restart the listener.

## Step 1: Run Claude Code in tmux

```bash
sudo apt update && sudo apt install -y tmux nginx certbot python3-certbot-nginx
# Install Node.js 18+ (NodeSource or nvm), then:
npm install -g @anthropic-ai/claude-code
tmux new -s claude          # start a tmux session called "claude"
cd ~/myproject && claude    # start Claude Code and sign in
```

Detach with `Ctrl+B`, then `D`. Claude Code continues to run. Come back with `tmux attach -t claude`.

## Step 2: Start the listener

```bash
git clone https://github.com/jjjsites/wrist-agent.git ~/wrist-agent
cd ~/wrist-agent
bash listener/make-key.sh
```

Write down the `KEY` line. You put it on the watch in Step 4. Do not save it on the server.

```bash
npm install -g pm2
WRIST_SESSION=claude WRIST_KEY_HASH=<your HASH> pm2 start listener/listener.js --name wrist-listener
pm2 save && pm2 startup
curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8787/wrist/state   # must print 401
```

Start the listener as the same Linux user that runs tmux. `WRIST_SESSION` is the name of
the tmux session from Step 1. The listener does not start without it.

Now add HTTPS:

1. Point your domain (for example `agent.example.com`) to the server with a DNS `A` record.
2. Copy `listener/nginx-wrist.conf` to `/etc/nginx/sites-available/wrist` and change `server_name`.
3. Turn it on and get a certificate:
   ```bash
   sudo ln -s /etc/nginx/sites-available/wrist /etc/nginx/sites-enabled/
   sudo nginx -t && sudo systemctl reload nginx
   sudo certbot --nginx -d agent.example.com
   ```
4. From your own computer, make sure that it answers:
   ```bash
   curl -s -H 'Authorization: Bearer <your KEY>' https://agent.example.com/wrist/state
   ```
   The answer looks like `{"mood":"idle","tail":[...]}`.

## Step 3: Build the watch app

1. Install [connect-iq-sdk-manager](https://github.com/lindell/connect-iq-sdk-manager-cli), then get the SDK and your watch files:
   ```bash
   connect-iq-sdk-manager agreement view     # read the Garmin SDK licence
   connect-iq-sdk-manager agreement accept
   connect-iq-sdk-manager login              # your Garmin account
   connect-iq-sdk-manager sdk set ^8
   connect-iq-sdk-manager device download -d fr165
   ```
2. Make a developer key. Keep it safe: an app update must use the same key.
   ```bash
   mkdir -p ~/.garmin
   openssl genrsa 4096 | openssl pkcs8 -topk8 -outform DER -nocrypt -out ~/.garmin/developer_key.der
   ```
3. Give the app its own id. Put the output in the `id` of `watch/manifest.xml`:
   ```bash
   uuidgen | tr -d '-'
   ```
4. If your watch is not a Forerunner 165, change `fr165` in `watch/manifest.xml` to your product id.
5. Open `watch/resources/properties/properties.xml`. Set `serverUrl` to `https://agent.example.com` and `watchKey` to your `KEY`.
6. Build:
   ```bash
   DEVICE=fr165 bash watch/build.sh
   ```

The result is `watch/bin/WristAgent.prg`. Do not share this file: it contains your key.

## Step 4: Install and pair the watch

1. Copy `WristAgent.prg` from the server to your computer (`scp`).
2. Connect the watch to the computer with the USB cable.
3. Copy `WristAgent.prg` into the `GARMIN/APPS` folder on the watch. On a Mac, use [OpenMTP](https://openmtp.ganeshrvel.com/).
4. Disconnect the watch.
5. On the watch, open the apps list and start **Wrist Agent**.
6. Make sure that your phone is near the watch and Garmin Connect is open.

The key is already in the app (Step 3, item 5), so the watch is paired. A sideloaded
app cannot get settings from the phone. To change the server or the key, edit
`properties.xml` and build again. If you publish the app in the Connect IQ store
(beta is fine), you can set the key in the Connect IQ phone app instead.

## Step 5: Test

1. Attach to tmux on the server (`tmux attach -t claude`).
2. Ask Claude Code to do a task that takes a minute. Clawd starts to type.
3. Ask Claude Code to do a task that needs your permission. Clawd jumps under a "!".
4. On the watch, press START and select **Enter**. The prompt on the server closes.
5. When the turn ends, Clawd cheers for 5 seconds, then walks around.

## Troubleshooting

| What you see | Cause | Fix |
| --- | --- | --- |
| Clawd sleeps, text `error -104` | The phone is not connected | Open Garmin Connect on the phone, keep Bluetooth on |
| Text `error 401` | Wrong key | Check `watchKey`, then build again |
| Text `error` with another negative number | The phone could not reach the server, or the server has no valid HTTPS | Test with `curl` from outside the server, run `certbot` again |
| Text `error 500` | The listener cannot find the tmux session | Check `WRIST_SESSION` and run the listener as the tmux user |
| A phrase does nothing | It starts with `/` | Slash commands are blocked on purpose |
| Mood stays `idle` | Claude Code is not in that tmux session | `tmux ls`, then fix `WRIST_SESSION` |

## Build it with Claude Code

Do not want to do it by hand? Paste [PROMPT.md](PROMPT.md) into Claude Code on your server.

## License

MIT. See [LICENSE](LICENSE).
