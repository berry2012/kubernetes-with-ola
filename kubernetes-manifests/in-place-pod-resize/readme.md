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







export REGION="eu-west-1"
export key_pair="aws-wale"
export LOCAL_SSH_KEY_FILE="~/.ssh/aws-wale.pem"
export AWS_PROFILE=default
export ANSIBLE_SERVER_PUBLIC_IP="$(aws ec2 describe-instances --filters "Name=tag-value,Values=ansible_controller_kubeadm_lab" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text --region ${REGION})"
ssh -i ${LOCAL_SSH_KEY_FILE} ubuntu@${ANSIBLE_SERVER_PUBLIC_IP}