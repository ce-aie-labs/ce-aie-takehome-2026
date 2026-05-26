# WXO_USAGE - watsonx Orchestrate Usage Guide

Multi-Agent, Multi-Tool RAG Assistant 과제용 watsonx Orchestrate 사용 가이드입니다. 그대로 복사한 뒤 선택한 시나리오에 맞게 이름, 설명, tool, Milvus collection 설정을 바꿔 사용하세요.

이 문서는 최소 구현 경로에 집중합니다. OpenAPI, MCP, evaluation CLI, 외부 RAG service는 선택 사항입니다.

## 0. Recommended Repository Structure

```text
<your-repo>/
├── README.md
├── agents/
│   ├── supervisor.yaml
│   ├── rag_specialist.yaml
│   └── tool_specialist.yaml
├── tools/
│   └── python/
│       └── business_tools.py
├── connections/
│   └── milvus.yaml
├── knowledge_base/
│   └── kb.yaml
├── data/
│   ├── sources.md
│   └── mock_records.json
├── docs/
│   └── validation.md
├── scripts/
│   └── import_all.sh
└── .env.example
```

## 1. Environment Setup

```bash
python3.11 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install --upgrade "ibm-watsonx-orchestrate[agentops]" "ibm-watsonx-ai==1.5.11" pymilvus

orchestrate env add --name my-env --url <SHARED_INSTANCE_URL>
orchestrate env activate my-env --api-key <SHARED_API_KEY>
orchestrate env list
orchestrate models list
```

Python 3.11+를 기본으로 사용하세요. 설치 또는 ADK 호환성 문제가 있으면 Python 3.12 환경으로 다시 시도하세요.
ADK 2.10.x 기준으로 `env add`는 `--name`과 `--url` 옵션이 필요합니다.
`orchestrate models list`에서 현재 환경에 노출되는 권장 모델을 확인한 뒤 agent YAML의 `llm` 값을 맞추세요.
제공된 SaaS 환경에서는 `groq/openai/gpt-oss-120b`가 기본 권장 모델로 확인되었습니다.

`.env.example` 예시:

```dotenv
# watsonx Orchestrate
WO_ENV_NAME=my-env
WO_INSTANCE_URL=<SHARED_INSTANCE_URL>
WO_API_KEY=replace_with_your_api_key

# watsonx.data Milvus - do not commit real password
MILVUS_HOST=ffbe47d6-2f04-4c96-b0be-fdf8658d2a08.d2n23mhr0m94463g3tdg.lakehouse.ibmappdomain.cloud
MILVUS_PORT=31140
MILVUS_DATABASE=candidateXX_XXXXXXXX
MILVUS_USER=ibmlhapikey_candidateXX
MILVUS_PASSWORD=replace_with_your_api_key

# watsonx.ai SDK test values. See WXAI_USAGE.md.
WATSONX_PROJECT_ID=<YOUR_PROJECT_ID>
WATSONX_URL=https://us-south.ml.cloud.ibm.com
WATSONX_APIKEY=replace_with_your_api_key
WATSONX_CHAT_MODEL_ID=openai/gpt-oss-120b
WATSONX_EMBED_MODEL_ID=intfloat/multilingual-e5-large
```

## 2. Python Tools

아래 예시는 하나의 파일에 Python tool 2개를 넣는 형태입니다. 첫 번째는 mock lookup, 두 번째는 계산 tool입니다. 선택한 시나리오에 맞게 이름과 로직을 바꾸세요.

```python
# tools/python/business_tools.py
from ibm_watsonx_orchestrate.agent_builder.tools import tool


MOCK_RECORDS = {
    "A-100": {"status": "available", "quantity": 42, "updated_at": "2026-05-27"},
    "B-200": {"status": "low_stock", "quantity": 3, "updated_at": "2026-05-27"},
}


@tool
def lookup_mock_record(record_id: str) -> dict:
    """
    Look up a mock business record by ID.

    Args:
        record_id: Business record ID, such as product, branch, plan, or case ID.
    Returns:
        Structured record data or a not_found status.
    """
    record = MOCK_RECORDS.get(record_id)
    if not record:
        return {"record_id": record_id, "status": "not_found"}
    return {"record_id": record_id, **record}


@tool
def calculate_margin(revenue: float, cost: float, discount_rate: float = 0.0) -> dict:
    """
    Calculate discounted revenue and gross margin.

    Args:
        revenue: Original revenue amount in KRW.
        cost: Cost amount in KRW.
        discount_rate: Discount rate as decimal, for example 0.1 for 10%.
    Returns:
        Discounted revenue, gross margin amount, and margin rate.
    """
    if revenue < 0 or cost < 0:
        return {"error": "revenue and cost must be non-negative"}
    if not 0 <= discount_rate < 1:
        return {"error": "discount_rate must be between 0 and 1"}

    discounted_revenue = revenue * (1 - discount_rate)
    margin = discounted_revenue - cost
    margin_rate = margin / discounted_revenue if discounted_revenue else 0
    return {
        "discounted_revenue": round(discounted_revenue),
        "margin": round(margin),
        "margin_rate": round(margin_rate, 4),
    }
```

## 3. Agent YAML

Collaborator agents를 supervisor보다 먼저 import하세요.

```yaml
# agents/rag_specialist.yaml
spec_version: v1
kind: native
name: rag_specialist_agent
llm: groq/openai/gpt-oss-120b
style: default
description: >
  Answers document-grounded questions from the scenario Knowledge Base.
  Use this for policy, guide, filing, terms, report, and source citation questions.
instructions: >
  Use only the Knowledge Base for factual claims. Cite each claim with
  [source_url#chunk_id] and page when available. If the retrieved evidence is
  insufficient, say what is missing and suggest where to verify it.
knowledge_base:
  - scenario_kb
```

```yaml
# agents/tool_specialist.yaml
spec_version: v1
kind: native
name: tool_specialist_agent
llm: groq/openai/gpt-oss-120b
style: default
description: >
  Calls Python tools for calculations, mock lookups, structured data lookup,
  or external-system style questions. Do not answer document policy questions.
instructions: >
  Select the relevant tool, call it with explicit arguments, and explain the
  result briefly. If required arguments are missing, ask for the missing values.
tools:
  - lookup_mock_record
  - calculate_margin
```

```yaml
# agents/supervisor.yaml
spec_version: v1
kind: native
name: scenario_supervisor
llm: groq/openai/gpt-oss-120b
style: react
description: |
  Supervisor for the selected scenario assistant. Routes document-grounded
  questions to rag_specialist_agent and calculation or structured lookup
  questions to tool_specialist_agent. Uses both collaborators for compound
  questions that require evidence plus a computed or lookup result.
instructions: |
  1. Classify the user's question as RAG, tool, compound, or unanswerable.
  2. Use rag_specialist_agent for evidence from documents.
  3. Use tool_specialist_agent for calculations and structured lookup.
  4. For compound questions, combine cited evidence and tool output.
  5. If the available documents/tools cannot answer, state the limitation.
collaborators:
  - rag_specialist_agent
  - tool_specialist_agent
```

## 4. watsonx.data Milvus Knowledge Base

이 과제의 필수 RAG 경로는 wxO built-in document upload Knowledge Base가 아닙니다.
문서를 직접 전처리하고 제공된 watsonx.data Milvus database에 적재한 뒤, wxO Knowledge Base가 해당 Milvus collection을 검색하도록 연결해야 합니다.

아래 예시는 이미 `scenario_chunks` collection에 chunk text, embedding, source metadata가 적재되어 있다고 가정합니다.
Milvus 적재 방법은 [MILVUS_USAGE.md](MILVUS_USAGE.md)를 참고하세요.

### 4.1 Connection YAML

connection YAML에는 실제 username/password를 쓰지 않습니다. credential은 import 후 CLI로 주입합니다.

```yaml
# connections/milvus.yaml
spec_version: v1
kind: connection
app_id: milvus_kb
resource:
  component: knowledge
  category: milvus
environments:
  draft:
    kind: basic
    type: team
    server_url: https://ffbe47d6-2f04-4c96-b0be-fdf8658d2a08.d2n23mhr0m94463g3tdg.lakehouse.ibmappdomain.cloud:31140
```

credential 주입:

```bash
orchestrate connections import -f connections/milvus.yaml
orchestrate connections set-credentials \
  --app-id milvus_kb \
  --environment draft \
  --username "$MILVUS_USER" \
  --password "$MILVUS_PASSWORD"
```

### 4.2 Knowledge Base YAML

```yaml
# knowledge_base/kb.yaml
spec_version: v1
kind: knowledge_base
name: scenario_kb
description: |
  watsonx.data Milvus knowledge base for the selected scenario.
prioritize_built_in_index: false
conversational_search_tool:
  index_config:
    - app_id: milvus_kb
      milvus:
        grpc_host: ffbe47d6-2f04-4c96-b0be-fdf8658d2a08.d2n23mhr0m94463g3tdg.lakehouse.ibmappdomain.cloud
        grpc_port: "31140"
        database: candidateXX_XXXXXXXX
        collection: scenario_chunks
        index: embedding
        embedding_model_id: intfloat/multilingual-e5-large
        limit: 5
        field_mapping:
          title: source
          body: text
          url: source_url
          custom_fields:
            page: page
            chunk_id: chunk_id
  generation:
    model_id: groq/openai/gpt-oss-120b
    prompt_instruction: |
      Answer only from retrieved Milvus chunks. Cite source_url, page, and chunk_id.
      If evidence is insufficient, say what is missing.
    max_docs_passed_to_llm: 5
    generated_response_length: Moderate
```

`grpc_host`와 `grpc_port`는 Milvus HTTP endpoint가 아니라 GRPC host/port여야 합니다.
`database`, `collection`, `index`, `embedding_model_id`, `field_mapping`은 본인이 실제로 만든 Milvus schema와 일치해야 합니다.

## 5. Import Script

```bash
# scripts/import_all.sh
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

orchestrate tools import -k python -f tools/python/business_tools.py

orchestrate connections import -f connections/milvus.yaml
orchestrate connections set-credentials \
  --app-id milvus_kb \
  --environment draft \
  --username "$MILVUS_USER" \
  --password "$MILVUS_PASSWORD"

orchestrate knowledge-bases import -f knowledge_base/kb.yaml
orchestrate knowledge-bases status -n scenario_kb

orchestrate agents import -f agents/rag_specialist.yaml
orchestrate agents import -f agents/tool_specialist.yaml
orchestrate agents import -f agents/supervisor.yaml

echo "Imported. Test in the wxO SaaS chat/preview UI with agent: scenario_supervisor"
```

Knowledge Base import 전에 Milvus collection 적재와 Python search sanity check를 먼저 끝내세요.
`orchestrate knowledge-bases import`는 Milvus에 문서를 넣어주는 명령이 아니라, 이미 존재하는 Milvus collection을 wxO에 연결하는 명령입니다.

## 6. Candidate README Template

제출 repository의 README에는 아래 내용을 최소한 포함하세요.

```markdown
# <Scenario Name> Assistant

## Problem
- Scenario:
- Customer persona:
- Business problem:
- Success criteria or KPI:

## Core Questions
| # | Question | Type | Expected route |
|---|---|---|---|
| 1 | ... | RAG | rag_specialist_agent |
| 2 | ... | Tool | tool_specialist_agent |
| 3 | ... | Compound | both |
| 4 | ... | RAG | rag_specialist_agent |
| 5 | ... | Unanswerable | supervisor |

## Architecture
- Supervisor:
- Collaborators:
- Tools:
- Knowledge Base: watsonx.data Milvus collection name, embedding model, field mapping

## Reproduce
1. Create venv and install dependencies.
2. Activate wxO environment.
3. Import tools, Knowledge Base, and agents.
4. Open wxO SaaS chat/preview and test `scenario_supervisor`.

## Technical Decisions
- LLM:
- Supervisor style:
- Collaborator style:
- Embedding:
- Chunking:
- Retrieval:

## Validation Results
| Question | Expected | Actual | Pass/Fail | Notes |
|---|---|---|---|---|

## Limitations and Next Steps

## AI / Code Assistant Usage
```

## 7. Debugging Tips

- `401` 또는 인증 실패: `orchestrate env activate <env> --api-key <api_key>`를 다시 실행하세요.
- `unknown collaborator`: collaborator agents를 supervisor보다 먼저 import하세요.
- Tool이 호출되지 않음: tool agent description에 tool의 역할을 더 구체적으로 적으세요.
- RAG 답변에 출처가 없음: RAG agent instructions에 citation 형식을 명시하고 validation 질문을 다시 테스트하세요.
- 검색 품질이 낮음: 문서 전처리, chunk size/overlap, metadata, 핵심 질문 phrasing을 함께 확인하세요.
- Milvus 접속 실패: host/port, `secure=True`, `db_name`, user/password 오타를 확인하세요.
- Knowledge Base가 검색을 못 함: `collection`, vector field(`index`), `embedding_model_id`, `field_mapping.body`가 실제 Milvus schema와 일치하는지 확인하세요.
- SaaS 환경에서는 `orchestrate chat ask`보다 wxO 웹 콘솔의 chat/preview 화면으로 최종 동작을 확인하세요.

## 8. Tested Against Provided SaaS

아래 항목은 2026년 5월 27일 KST 기준으로 제공된 wxO SaaS 인스턴스에서 확인했습니다. API key 값은 문서나 repository에 저장하지 않았습니다.

- `ibm-watsonx-orchestrate[agentops]` 설치 결과: ADK `2.10.0`
- `orchestrate env add --name ce-aie-takehome --url <INSTANCE_URL>` 성공
- `orchestrate env activate ce-aie-takehome --api-key <API_KEY>` 성공
- `orchestrate models list`에서 `groq/openai/gpt-oss-120b`가 기본 권장 모델로 표시됨
- Python tool 2개 import 성공
- Knowledge Base YAML은 `documents/vector_index`가 아니라 `conversational_search_tool.index_config[].milvus` 형태여야 함
- Native collaborator 2개와 supervisor 1개 import 성공

## 9. References

- IBM watsonx Orchestrate ADK: https://developer.watson-orchestrate.ibm.com/
- IBM watsonx Orchestrate product documentation: https://www.ibm.com/docs/en/watsonx/watson-orchestrate/base?topic=getting-started-watsonx-orchestrate
- IBM watsonx Orchestrate ADK examples: https://github.com/IBM/ibm-watsonx-orchestrate-adk/tree/main/examples
- watsonx.data Milvus guide: https://cloud.ibm.com/docs/watsonxdata?topic=watsonxdata-working_with_milvus
