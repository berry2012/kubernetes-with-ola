# 🔥 Resize Kubernetes Pod Resources LIVE — No Downtime, No Restart!

## resize memory

```bash
kubectl patch pod cpu-monitor --subresource resize --patch \
  '{"spec":{"containers":[{"name":"cpu-monitor", "resources":{"requests":{"memory":"300Mi"}, "limits":{"memory":"300Mi"}}}]}}'
```

## resize cpu

```bash
kubectl patch pod cpu-monitor --subresource resize --patch \
  '{"spec":{"containers":[{"name":"cpu-monitor", "resources":{"requests":{"cpu":"300m"}, "limits":{"cpu":"300m"}}}]}}'
```

## view pod

```bash
kubectl get pod cpu-monitor -o yaml | grep resources -A 2
```
