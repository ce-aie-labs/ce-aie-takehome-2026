# watsonx.data Milvus Usage Guide

본 문서는 과제에서 제공되는 watsonx.data Milvus database를 사용하는 방법을 설명합니다.

가장 중요한 원칙은 세 가지입니다.

- 최종 제출의 필수 RAG 경로는 **watsonx.data Milvus에 직접 적재한 collection + wxO Knowledge Base external Milvus 연결**입니다.
- wxO built-in document upload Knowledge Base는 전처리, embedding 모델, index schema를 직접 통제하기 어렵기 때문에 필수 RAG 요건으로 인정하지 않습니다.
- 개인별 database 이름, user, password/API key는 절대 GitHub repository에 commit하지 않습니다.

## 1. Provided Connection Values

아래 접속 정보는 공통입니다.

```text
host = ffbe47d6-2f04-4c96-b0be-fdf8658d2a08.d2n23mhr0m94463g3tdg.lakehouse.ibmappdomain.cloud
port = 31140
ssl = true
```

지원자별로 아래 값만 본인 정보로 바꿔서 사용합니다.

```text
database = 본인에게 전달된 candidateXX_XXXXXXXX
user = 본인에게 전달된 ibmlhapikey_candidateXX
password = 본인에게 전달된 API key
```

제출 repository에는 아래처럼 placeholder만 남기세요.

```dotenv
MILVUS_HOST=ffbe47d6-2f04-4c96-b0be-fdf8658d2a08.d2n23mhr0m94463g3tdg.lakehouse.ibmappdomain.cloud
MILVUS_PORT=31140
MILVUS_DATABASE=candidateXX_XXXXXXXX
MILVUS_USER=ibmlhapikey_candidateXX
MILVUS_PASSWORD=replace_with_your_api_key
MILVUS_COLLECTION=scenario_chunks
```

## 2. Required Workflow

1. 선택한 시나리오의 공개 문서 8-12개를 수집합니다.
2. 문서별 source URL, 라이선스/이용 조건, 파일명을 `data/sources.md`에 정리합니다.
3. 문서를 직접 전처리하고 chunk를 만듭니다.
4. watsonx.ai embedding 또는 동등한 embedding 모델로 chunk vector를 생성합니다.
5. 제공된 watsonx.data Milvus database에 collection을 만들고 chunk/vector/metadata를 적재합니다.
6. wxO Knowledge Base YAML에서 해당 Milvus collection을 external vector index로 연결합니다.
7. RAG collaborator agent가 Knowledge Base를 사용하도록 설정합니다.
8. 핵심 질문 5개 중 최소 2개에서 Milvus 검색과 출처 인용이 실제로 되는지 검증합니다.

RAG collaborator instruction 예시:

```text
Use the Knowledge Base for policy, terms, guide, filing, and report questions.
Answer only from retrieved Milvus chunks. Cite each factual claim with
[source_url#chunk_id] and page when available. If the Knowledge Base does not
contain enough evidence, say what is missing instead of guessing.
```

## 3. Connect With Python

```bash
python -m pip install pymilvus
```

```python
import os
from pymilvus import connections, utility

connections.connect(
    alias="default",
    host=os.environ["MILVUS_HOST"],
    port=os.environ.get("MILVUS_PORT", "31140"),
    user=os.environ["MILVUS_USER"],
    password=os.environ["MILVUS_PASSWORD"],
    secure=True,
    db_name=os.environ["MILVUS_DATABASE"],
)

print(utility.list_collections())
```

## 4. Suggested Collection Schema

아래 schema는 예시입니다. 다른 schema를 사용해도 되지만, README에 schema와 이유를 설명해야 합니다.

`intfloat/multilingual-e5-large`를 사용하면 vector dimension은 `1024`입니다. 다른 embedding 모델을 쓰면 반드시 dimension을 바꾸세요.

```python
import os
from pymilvus import Collection, CollectionSchema, FieldSchema, DataType, utility

COLLECTION = os.environ.get("MILVUS_COLLECTION", "scenario_chunks")
DIM = 1024

fields = [
    FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=True),
    FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=DIM),
    FieldSchema(name="text", dtype=DataType.VARCHAR, max_length=8192),
    FieldSchema(name="source", dtype=DataType.VARCHAR, max_length=512),
    FieldSchema(name="source_url", dtype=DataType.VARCHAR, max_length=1024),
    FieldSchema(name="page", dtype=DataType.INT64),
    FieldSchema(name="chunk_id", dtype=DataType.VARCHAR, max_length=128),
]

schema = CollectionSchema(fields=fields, description="Scenario RAG chunks")

if not utility.has_collection(COLLECTION):
    collection = Collection(COLLECTION, schema=schema)
    collection.create_index(
        field_name="embedding",
        index_params={
            "index_type": "HNSW",
            "metric_type": "COSINE",
            "params": {"M": 16, "efConstruction": 200},
        },
    )
else:
    collection = Collection(COLLECTION)
```

## 5. Insert Chunks

아래 코드는 이미 chunk와 embedding vector를 만든 뒤 Milvus에 넣는 최소 형태입니다. 실제 제출물에서는 본인이 만든 전처리/chunking/embedding 코드를 포함하고, chunk size와 overlap 선택 근거를 README에 적으세요.

```python
def insert_chunks(collection, chunks: list[dict]) -> None:
    """
    chunks item example:
    {
        "embedding": [0.01, ...],        # length 1024 for multilingual-e5-large
        "text": "chunk text",
        "source": "policy_01.pdf",
        "source_url": "https://example.com/policy_01.pdf",
        "page": 3,
        "chunk_id": "policy_01_p3_c2",
    }
    """
    collection.insert([
        [c["embedding"] for c in chunks],
        [c["text"] for c in chunks],
        [c["source"] for c in chunks],
        [c["source_url"] for c in chunks],
        [c.get("page", 0) for c in chunks],
        [c["chunk_id"] for c in chunks],
    ])
    collection.flush()
    collection.load()
```

## 6. Search Sanity Check

wxO 연결 전, Python으로 검색 결과와 metadata가 잘 나오는지 확인하세요.

```python
def search(collection, query_vector: list[float], limit: int = 5) -> list[dict]:
    collection.load()
    results = collection.search(
        data=[query_vector],
        anns_field="embedding",
        param={"metric_type": "COSINE", "params": {"ef": 64}},
        limit=limit,
        output_fields=["text", "source", "source_url", "page", "chunk_id"],
    )[0]
    return [
        {
            "score": hit.distance,
            "text": hit.entity.get("text"),
            "source": hit.entity.get("source"),
            "source_url": hit.entity.get("source_url"),
            "page": hit.entity.get("page"),
            "chunk_id": hit.entity.get("chunk_id"),
        }
        for hit in results
    ]
```

## 7. Connect From wxO Knowledge Base

Milvus collection을 적재한 뒤 [WXO_USAGE.md](WXO_USAGE.md)의 external Milvus Knowledge Base YAML 예시를 사용하세요.

중요한 연결값:

- `app_id`: wxO connection 이름. 예: `milvus_kb`
- `grpc_host`: 공통 Milvus GRPC host. `https://` 없이 host만 입력합니다.
- `grpc_port`: Milvus GRPC port. 제공값은 `31140`입니다.
- `database`: 본인에게 전달된 database
- `collection`: 본인이 만든 collection
- `index`: vector field 이름. 권장: `embedding`
- `embedding_model_id`: 적재 때 사용한 embedding 모델
- `field_mapping.body`: chunk text field. 권장: `text`
- `field_mapping.url`: 출처 URL field. 권장: `source_url`

## 8. Notes

- `list_database()` 권한은 제공되지 않습니다. 본인에게 전달된 database 이름으로만 접속하세요.
- collection 이름은 자유롭게 만들 수 있지만, 후보자별 database 안에서 관리해야 합니다.
- API key는 개인별 비밀값입니다. GitHub 저장소나 문서에 commit하지 마세요.
- connection 실패 시 host/port, `secure=True`, `db_name`, user/password 오타를 먼저 확인하세요.
- wxO Knowledge Base에는 Milvus HTTP endpoint가 아니라 GRPC host/port를 사용해야 합니다.
- Milvus dimension mismatch가 나면 embedding 모델 출력 차원과 collection `FLOAT_VECTOR dim`을 확인하세요.
