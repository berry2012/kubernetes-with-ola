# Deploy Mistral 7B V3


## Get Started

1. Create secret - Secret is optional and only required for accessing gated models, you can skip this step if you are not using gated models

2. Create PV,PVC. PVC is used to store the model cache and it is optional, you can use hostPath or other storage options

3. Create a deployment file for vLLM to run the model server. The following example deploys the Mistral-7B-Instruct-v0.3 model:

```bash
k apply -f ../direct
```

4. Watch the pod creation

```bash
watch kubectl get pods
```

## Test - Run curl 


```bash
k port-forward svc/mistral7bv3-gpu 8080:80  

```

```bash

curl -s http://localhost:8080/v1/completions \
-H "Content-Type: application/json" \
-d '{
    "model": "mistralai/Mistral-7B-Instruct-v0.3",
    "prompt": "You are a content moderation system. Analyze the following message and respond with a JSON object containing: {\"action\": \"allow|warn|block|timeout\", \"reason\": \"explanation\", \"confidence\": 0.0-1.0, \"categories\": [\"list of violation types\"]}. Be strict about toxic content.\n\nAnalyze this message: \"You are the worst human being, you make me sick to my stomach.\"",
    "temperature": 0
}' | jq .


# check timing
curl -w "time_namelookup: %{time_namelookup}, time_connect: %{time_connect}, time_appconnect: %{time_appconnect}, time_pretransfer: %{time_pretransfer}, time_redirect: %{time_redirect}, time_starttransfer: %{time_starttransfer}, time_total: %{time_total}\n" \
-s http://localhost:8080/v1/completions \
-H "Content-Type: application/json" \
-d '{
    "model": "mistralai/Mistral-7B-Instruct-v0.3",
    "prompt": "You are a content moderation system. Analyze the following message and respond with a JSON object containing: {\"action\": \"allow|warn|block|timeout\", \"reason\": \"explanation\", \"confidence\": 0.0-1.0, \"categories\": [\"list of violation types\"]}. Be strict about toxic content.\n\nAnalyze this message: \"You are the worst human being, you make me sick to my stomach.\"",
    "temperature": 0
}' 
```

## Clean up

```bash
k delete -f ../direct
```

## Speed-up Pod Startup time

- Using Amazon FSx Luster
- Init Container to download model

```bash
k logs -f pod -c model-download 

k logs -f pod -c vllm
```

- Access the service

```bash
k port-forward svc/mistral7bv3-gpu 8080:80  

```

```bash

curl -s http://localhost:8080/v1/completions \
-H "Content-Type: application/json" \
-d '{
    "model": "/tmp/models/mistral-7b-v0-3",
    "prompt": "You are a content moderation system. Analyze the following message and respond with a JSON object containing: {\"action\": \"allow|warn|block|timeout\", \"reason\": \"explanation\", \"confidence\": 0.0-1.0, \"categories\": [\"list of violation types\"]}. Be strict about toxic content.\n\nAnalyze this message: \"You are the worst human being, you make me sick to my stomach.\"",
    "temperature": 0
}' | jq '.'

# get only the text result from the output

curl -s http://localhost:8080/v1/completions \
-H "Content-Type: application/json" \
-d '{
    "model": "/tmp/models/mistral-7b-v0-3",
    "prompt": "You are a content moderation system. Analyze the following message and respond with a JSON object containing: {\"action\": \"allow|warn|block|timeout\", \"reason\": \"explanation\", \"confidence\": 0.0-1.0, \"categories\": [\"list of violation types\"]}. Be strict about toxic content.\n\nAnalyze this message: \"You are the worst human being, you make me sick to my stomach.\"",
    "temperature": 0,
    "max_tokens": 100
}' | jq -r '.choices[0].text'


# check timing
curl -w "time_namelookup: %{time_namelookup}, time_connect: %{time_connect}, time_appconnect: %{time_appconnect}, time_pretransfer: %{time_pretransfer}, time_redirect: %{time_redirect}, time_starttransfer: %{time_starttransfer}, time_total: %{time_total}\n" \
-s http://localhost:8080/v1/completions \
-H "Content-Type: application/json" \
-d '{
    "model": "/tmp/models/mistral-7b-v0-3",
    "prompt": "You are a content moderation system. Analyze the following message and respond with a JSON object containing: {\"action\": \"allow|warn|block|timeout\", \"reason\": \"explanation\", \"confidence\": 0.0-1.0, \"categories\": [\"list of violation types\"]}. Be strict about toxic content.\n\nAnalyze this message: \"You are the worst human being, you make me sick to my stomach.\"",
    "temperature": 0
}' 
```

## Clean up

```bash
k delete -f ../predownloaded
```


## Observability

- Monitoring GPU:  https://builder.aws.com/content/2tMbVJ5tU3AcNs3NyurZVyX3mil/navigating-the-aws-accelerated-computing-instance-choices

- 


## Cost Monitoring 

