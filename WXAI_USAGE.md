# watsonx.ai Usage Guide

본 문서는 과제에서 watsonx.ai API key, project ID, service URL을 확인하고 Python SDK로 간단히 연결 테스트하는 방법을 설명합니다.

아래 SDK/API 호출 코드는 연결 확인을 위한 참고 예시입니다. 선택한 구현 방식에 따라 LangChain, REST API, 다른 SDK wrapper를 사용해도 됩니다. 단, ASSIGNMENT.md의 최소 요구사항, 보안 원칙, 재현 가능성, 검증 결과 제출은 반드시 충족해야 합니다.

실제 API key는 절대 GitHub repository에 commit하지 마세요. README, `.env.example`, screenshot, notebook output에도 실제 key를 남기면 안 됩니다.

## 1. What You Need

| 값 | 예시 | 어디서 확인하나 |
|---|---|---|
| `WATSONX_PROJECT_ID` | `216c1c8e-...` | watsonx.ai Project -> Manage -> General -> Details |
| `WATSONX_URL` | `https://us-south.ml.cloud.ibm.com` | 사용 중인 watsonx.ai region URL |
| `WATSONX_APIKEY` | 실제 값은 commit 금지 | IBM Cloud API keys |

이 저장소에 `videos/04_getwxaiapikey.mp4`가 함께 제공되는 경우, API key와 project ID를 찾는 흐름은 해당 영상을 참고하세요.

Region별 URL은 IBM SDK 문서의 authentication section을 기준으로 확인할 수 있습니다. Dallas region은 아래 값을 사용합니다.

```text
https://us-south.ml.cloud.ibm.com
```

## 2. Install SDK

Python 3.11 또는 3.12 환경을 권장합니다.

```bash
python3.11 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install "ibm-watsonx-ai==1.5.11"
```

설치 확인:

```bash
python - <<'PY'
import ibm_watsonx_ai
print(ibm_watsonx_ai.__version__)
PY
```

기대 결과:

```text
1.5.11
```

## 3. Set Environment Variables

API key는 shell 환경 변수로만 주입하세요. `.env` 파일을 만들 수는 있지만, `.env`는 반드시 `.gitignore`에 포함되어야 합니다.

```bash
export WATSONX_PROJECT_ID="<YOUR_PROJECT_ID>"
export WATSONX_URL="https://us-south.ml.cloud.ibm.com"

# 입력값이 터미널에 보이지 않게 API key를 받습니다.
read -rsp "WATSONX_APIKEY: " WATSONX_APIKEY
export WATSONX_APIKEY
echo
```

`.env.example`에는 실제 key 대신 placeholder만 남기세요.

```dotenv
WATSONX_PROJECT_ID=<YOUR_PROJECT_ID>
WATSONX_URL=https://us-south.ml.cloud.ibm.com
WATSONX_APIKEY=replace_with_your_api_key
WATSONX_CHAT_MODEL_ID=openai/gpt-oss-120b
WATSONX_EMBED_MODEL_ID=intfloat/multilingual-e5-large
```

## 4. Test 1 - Client and Model Specs

먼저 credential, project ID, URL이 맞는지 모델 목록 조회로 확인합니다.

```bash
python - <<'PY'
import os
from ibm_watsonx_ai import APIClient, Credentials

credentials = Credentials(
    url=os.environ["WATSONX_URL"],
    api_key=os.environ["WATSONX_APIKEY"],
)
client = APIClient(
    credentials=credentials,
    project_id=os.environ["WATSONX_PROJECT_ID"],
)

specs = client.foundation_models.get_model_specs(limit=20)
resources = specs.get("resources", [])

print("client ok")
print("model count:", len(resources))
for item in resources[:5]:
    print("-", item.get("model_id") or item.get("id"))
PY
```

`client ok`와 모델 ID 목록이 나오면 기본 인증은 성공입니다.

## 5. Test 2 - Chat Completion

wxO agent YAML의 모델 ID는 provider prefix를 포함해 `groq/openai/gpt-oss-120b`처럼 사용하지만, watsonx.ai Python SDK에서는 model ID를 `openai/gpt-oss-120b`처럼 사용합니다.

```bash
python - <<'PY'
import os
from ibm_watsonx_ai import Credentials
from ibm_watsonx_ai.foundation_models import ModelInference

credentials = Credentials(
    url=os.environ["WATSONX_URL"],
    api_key=os.environ["WATSONX_APIKEY"],
)

model_id = os.getenv("WATSONX_CHAT_MODEL_ID", "openai/gpt-oss-120b")
model = ModelInference(
    model_id=model_id,
    credentials=credentials,
    project_id=os.environ["WATSONX_PROJECT_ID"],
    params={
        "temperature": 0.0,
        "max_tokens": 128,
        # gpt-oss 계열은 짧은 테스트에서 reasoning만 길게 쓰지 않도록 낮게 둡니다.
        "reasoning_effort": "low",
    },
)

response = model.chat(
    messages=[
        {"role": "system", "content": "You answer briefly in Korean."},
        {"role": "user", "content": "watsonx.ai 연결 테스트 문장을 하나만 작성해줘."},
    ]
)

message = response["choices"][0]["message"]
print(message.get("content") or message.get("reasoning_content"))
PY
```

예상 결과는 짧은 한국어 문장입니다.

```text
watsonx.ai 연결이 정상적으로 작동합니다.
```

대체로 아래 모델도 사용할 수 있습니다. 사용 가능 여부는 project/region 권한에 따라 달라질 수 있습니다.

```text
openai/gpt-oss-120b
meta-llama/llama-3-3-70b-instruct
ibm/granite-4-h-small
```

## 6. Test 3 - Embeddings

RAG 실험에는 한국어 검색 품질을 위해 multilingual embedding을 권장합니다.

```bash
python - <<'PY'
import os
from ibm_watsonx_ai import Credentials
from ibm_watsonx_ai.foundation_models import Embeddings
from ibm_watsonx_ai.metanames import EmbedTextParamsMetaNames as EmbedParams

credentials = Credentials(
    url=os.environ["WATSONX_URL"],
    api_key=os.environ["WATSONX_APIKEY"],
)

model_id = os.getenv("WATSONX_EMBED_MODEL_ID", "intfloat/multilingual-e5-large")
embedding = Embeddings(
    model_id=model_id,
    credentials=credentials,
    project_id=os.environ["WATSONX_PROJECT_ID"],
    params={
        EmbedParams.TRUNCATE_INPUT_TOKENS: 128,
        EmbedParams.RETURN_OPTIONS: {"input_text": False},
    },
)

vector = embedding.embed_query(text="query: watsonx.ai 연결 테스트")
print("embedding ok")
print("model:", model_id)
print("dimension:", len(vector))
print("first value:", round(float(vector[0]), 6))
PY
```

확인된 embedding 차원:

| Model ID | Dimension | Note |
|---|---:|---|
| `intfloat/multilingual-e5-large` | 1024 | 한국어 RAG 권장 |
| `ibm/granite-embedding-278m-multilingual` | 768 | IBM multilingual embedding |

Milvus collection을 직접 만들 경우 `FLOAT_VECTOR`의 `dim`은 embedding model dimension과 반드시 같아야 합니다.

## 7. Common Errors

| 증상 | 원인 | 확인할 것 |
|---|---|---|
| `401` 또는 authentication 실패 | API key 오류 또는 만료/권한 문제 | `WATSONX_APIKEY`, IBM Cloud API key 권한 |
| `403` | project 접근 권한 없음 | 해당 IBMid가 project에 접근 가능한지 확인 |
| `404` 또는 model not found | region/project에서 모델 미제공 | `get_model_specs()`로 사용 가능한 model ID 확인 |
| `project_id is mandatory` | project ID 미설정 | `WATSONX_PROJECT_ID` export 여부 |
| chat 응답에 `content`가 비어 있음 | gpt-oss reasoning token이 먼저 사용됨 | `reasoning_effort: low`, `max_tokens` 증가 |
| embedding dimension mismatch | Milvus schema와 embedding model 차원 불일치 | `len(vector)`와 collection `dim` 비교 |

## 8. Tested Locally

아래 항목은 2026년 5월 27일 KST 기준으로 확인했습니다. 실제 API key 값은 문서, 커밋, 출력에 저장하지 않았습니다.

- `ibm-watsonx-ai==1.5.11` 설치 및 import
- `APIClient(...).foundation_models.get_model_specs(limit=20)`
- `ModelInference.chat()` with `openai/gpt-oss-120b`
- `Embeddings.embed_query()` with `intfloat/multilingual-e5-large`
- `Embeddings.embed_query()` with `ibm/granite-embedding-278m-multilingual`

## 9. References

- IBM watsonx.ai Python SDK v1.5.11: https://ibm.github.io/watsonx-ai-python-sdk/v1.5.11/index.html
- SDK installation: https://ibm.github.io/watsonx-ai-python-sdk/v1.5.11/install.html
- SDK authentication: https://ibm.github.io/watsonx-ai-python-sdk/v1.5.11/setup_cloud.html
- `ModelInference`: https://ibm.github.io/watsonx-ai-python-sdk/v1.5.11/fm_model_inference.html
- `Embeddings`: https://ibm.github.io/watsonx-ai-python-sdk/v1.5.11/fm_embeddings.html
- LangChain IBM integrations: https://docs.langchain.com/oss/python/integrations/providers/ibm
- watsonx.ai REST API: https://cloud.ibm.com/apidocs/watsonx-ai
