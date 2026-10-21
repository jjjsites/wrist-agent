# Prompt: build my Wrist Agent

Paste the text below into Claude Code on your server. Replace the three values
in angle brackets first.

---

I want to control you from my Garmin watch with the Wrist Agent project:
https://github.com/jjjsites/wrist-agent

My details:
- Domain for the listener: <agent.example.com> (its DNS A record points to this server)
- tmux session you run in: <claude>
- Watch product id: <fr165>

Do this, in order, and stop to ask me only when you need my action:

1. Read the README of the repo, then clone it to ~/wrist-agent.
2. Check that tmux, nginx, certbot, Node.js 18+ and pm2 are installed. Install what is missing.
3. Make the watch key with listener/make-key.sh. Show me the KEY once. Never write it to a file other than watch/resources/properties/properties.xml.
4. Start the listener with pm2 as my user, with WRIST_SESSION and WRIST_KEY_HASH set. Check that a call with no key returns 401.
5. Set up nginx from listener/nginx-wrist.conf for my domain, then run certbot. Check that https://<domain>/wrist/state returns JSON with the key.
6. Install connect-iq-sdk-manager. Show me the Garmin SDK licence and wait for me to accept it. Ask me to run the login myself.
7. Download the SDK and my watch's device files. Make a developer key in ~/.garmin. Give the app a new id in watch/manifest.xml and set my product id.
8. Put my domain and the KEY in properties.xml, then build with watch/build.sh.
9. Tell me how to copy watch/bin/WristAgent.prg to my watch over USB.
10. When I say it is installed, ask me to start a task, and confirm that the watch shows the mood.

Rules:
- Keep the listener on 127.0.0.1. Never open port 8787 in the firewall.
- Never print the KEY again after step 3, and never commit properties.xml with the key in it.
