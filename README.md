# workbox — step 1: isolated Claude Code on k3s
 
Claude Code runs permanently inside the pod, in a tmux session, with `--dangerously-skip-permissions`.
You attach to it, work, detach; it keeps running.
 
## Build & load
 
Two images from one Dockerfile (CI pushes both to ghcr.io on every push to master):

| target   | tag                     | contents                              |
|----------|-------------------------|---------------------------------------|
| `base`   | `workbox:latest`        | Claude Code + toolbox                 |
| `ghidra` | `workbox:latest-ghidra` | base + REA + Ghidra 12.1.4 + JDK 21   |

```bash
docker build --platform linux/amd64 --target base   -t workbox:latest        ./container
docker build --platform linux/amd64 --target ghidra -t workbox:latest-ghidra ./container
docker save workbox:latest | sudo k3s ctr images import -     # on the node (or push to the registry)
```
 
## Deploy
 
Requires the [agent-sandbox](https://github.com/kubernetes-sigs/agent-sandbox) controller and CRDs.
Pick the image in `k8s/workbox.yaml` (defaults to `latest-ghidra`).

```bash
kubectl apply -f k8s/workbox.yaml
kubectl -n workbox wait --for=condition=Ready sandbox/workbox
```
 
Auth, pick one:
- **Interactive:** attach (below) and run `/login`. Stored on the `claude-home` volume, survives restarts.
- **Subscription token:** on your laptop run `claude setup-token`, then
  `kubectl -n workbox create secret generic claude-auth --from-literal=CLAUDE_CODE_OAUTH_TOKEN=...`
- **API key:** `kubectl -n workbox create secret generic claude-auth --from-literal=ANTHROPIC_API_KEY=sk-ant-...`
After creating the secret, restart the pod: `kubectl -n workbox delete pod workbox` (the Sandbox controller recreates it; volumes are kept).
 
## Connect / disconnect
 
```bash
kubectl -n workbox exec -it workbox -- tmux attach -t claude
```
 
- Detach (leave Claude running): **Ctrl-b** then **d**. Closing the terminal also just detaches.
- Scroll back: mouse wheel, or Ctrl-b [ .
- First start asks you to confirm bypass-permissions mode and set up the theme; that's remembered.
- After `/exit`, you get a prompt: Enter restarts Claude, `s` opens a bash shell (exit it to get Claude back); it auto-restarts after 10 s. Use `/resume` to pick up an earlier conversation.
- A plain shell next to the running session: `kubectl -n workbox exec -it workbox -- bash`, or Ctrl-b c inside tmux for a new window.
- Copy files: `kubectl -n workbox cp ./file workbox:/work/` (use the pod name if your kubectl needs it).
## What the agent can and can't do
 
Inside the pod it can do anything without asking: read and write `/work` and `$HOME`, run commands, and use HTTPS to the internet.
 
It can't:
- get root, install system packages (the root filesystem is read-only), or escalate privileges.
- see the Kubernetes API (it has no token), your LAN, or other cluster services (egress is blocked to private ranges).
- touch the host (no hostPath, host network or host PID).
It can still send anything inside the pod (including your auth token) anywhere on the internet over HTTPS, so don't put
secrets in `/work` you wouldn't want exposed. To tighten this, use Cilium FQDN egress or gVisor; both are optional extras.
 
