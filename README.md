# workbox — step 1: isolated Claude Code on k3s
 
Claude Code runs permanently inside the pod, in a tmux session, with `--dangerously-skip-permissions`.
You attach to it, work, detach; it keeps running.
 
## Build & load
 
```bash
docker build --platform linux/amd64 -t workbox:1 ./container
docker save workbox:1 | sudo k3s ctr images import -     # on the node (or push to the registry)
```
 
## Deploy
 
```bash
kubectl apply -f k8s/claude.yaml
kubectl -n claude rollout status deploy/claude
```
 
Auth, pick one:
- **Interactive:** attach (below) and run `/login`. Stored on the `claude-home` volume, survives restarts.
- **Subscription token:** on your laptop run `claude setup-token`, then
  `kubectl -n claude create secret generic claude-auth --from-literal=CLAUDE_CODE_OAUTH_TOKEN=...`
- **API key:** `kubectl -n claude create secret generic claude-auth --from-literal=ANTHROPIC_API_KEY=sk-ant-...`
After creating the secret: `kubectl -n claude rollout restart deploy/claude`.
 
## Connect / disconnect
 
```bash
kubectl -n claude exec -it deploy/claude -- tmux attach -t claude
```
 
- Detach (leave Claude running): **Ctrl-b** then **d**. Closing the terminal also just detaches.
- Scroll back: mouse wheel, or Ctrl-b [ .
- First start asks you to confirm bypass-permissions mode and set up the theme; that's remembered.
- After `/exit`, you get a prompt: Enter restarts Claude, `s` opens a bash shell (exit it to get Claude back); it auto-restarts after 10 s. Use `/resume` to pick up an earlier conversation.
- A plain shell next to the running session: `kubectl -n claude exec -it deploy/claude -- bash`, or Ctrl-b c inside tmux for a new window.
- Copy files: `kubectl -n claude cp ./file deploy/claude:/work/` (use the pod name if your kubectl needs it).
## What the agent can and can't do
 
Inside the pod it can do anything without asking: read and write `/work` and `$HOME`, run commands, and use HTTPS to the internet.
 
It can't:
- get root, install system packages (the root filesystem is read-only), or escalate privileges.
- see the Kubernetes API (it has no token), your LAN, or other cluster services (egress is blocked to private ranges).
- touch the host (no hostPath, host network or host PID).
It can still send anything inside the pod (including your auth token) anywhere on the internet over HTTPS, so don't put
secrets in `/work` you wouldn't want exposed. To tighten this, use Cilium FQDN egress or gVisor; both are optional extras.
 
