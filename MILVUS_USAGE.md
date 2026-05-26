# watsonx.data Milvus Usage Guide

본 문서는 과제에서 제공되는 watsonx.data Milvus database를 사용하는 방법을 설명합니다.

가장 중요한 원칙은 두 가지입니다.

- 과제의 필수 RAG 경로는 **wxO Knowledge Base + 제공 Milvus database**입니다.
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
```

## 2. Required Path: wxO Knowledge Base

과제 제출물에서는 wxO agent가 Knowledge Base를 통해 Milvus 검색 결과를 사용해야 합니다.

권장 작업 흐름:

1. 선택한 시나리오의 공개 문서 8-12개를 수집합니다.
2. 문서별 source URL, 라이선스/이용 조건, 파일명을 `data/sources.md`에 정리합니다.
3. chunk size, overlap, embedding 모델을 정하고 README에 근거를 적습니다.
4. wxO Knowledge Base 설정에서 제공된 Milvus 접속값을 사용합니다.
5. RAG collaborator agent의 instructions에 출처 표기 형식을 명시합니다.
6. 핵심 질문 5개 중 최소 2개에서 Knowledge Base 검색과 출처 인용이 실제로 되는지 검증합니다.

RAG collaborator instruction 예시:

```text
Use the Knowledge Base for policy, terms, guide, filing, and report questions.
Answer only from retrieved sources. Cite each factual claim with [filename:page]
or [source_url#chunk_id]. If the Knowledge Base does not contain enough
evidence, say what is missing instead of guessing.
```

## 3. Optional Path: Python Sanity Check

아래 코드는 Milvus 접속이 되는지 확인하거나, collection 구조를 이해하기 위한 선택 예시입니다. 과제 필수 구현은 별도 Python retrieval tool이 아니라 wxO Knowledge Base 경로로 충족할 수 있습니다.

```bash
python -m pip install pymilvus
```

```python
from pymilvus import connections, utility

HOST = "ffbe47d6-2f04-4c96-b0be-fdf8658d2a08.d2n23mhr0m94463g3tdg.lakehouse.ibmappdomain.cloud"
PORT = "31140"
DATABASE = "candidateXX_XXXXXXXX"  # 본인 database로 변경
USER = "ibmlhapikey_candidateXX"   # 본인 user로 변경
PASSWORD = "YOUR_API_KEY"          # 본인 API key로 변경

connections.connect(
    alias="default",
    host=HOST,
    port=PORT,
    user=USER,
    password=PASSWORD,
    secure=True,
    db_name=DATABASE,
)

print(utility.list_collections())
```

## 4. Optional: Create, Insert, Search

아래 예시는 작은 toy collection으로 Milvus API 동작을 확인하는 용도입니다. 실제 과제 문서 RAG에는 사용하는 embedding 모델의 차원과 collection schema를 일치시켜야 합니다.

```python
from pymilvus import Collection, CollectionSchema, FieldSchema, DataType

schema = CollectionSchema(
    fields=[
        FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=False),
        FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=4),
        FieldSchema(name="text", dtype=DataType.VARCHAR, max_length=512),
        FieldSchema(name="source", dtype=DataType.VARCHAR, max_length=512),
    ],
    description="sample collection for connectivity test",
)

collection = Collection("sample_documents", schema=schema)

collection.insert([
    [1, 2, 3],
    [
        [0.1, 0.2, 0.3, 0.4],
        [0.2, 0.1, 0.4, 0.3],
        [0.9, 0.8, 0.7, 0.6],
    ],
    [
        "first document",
        "second document",
        "third document",
    ],
    [
        "sample://first",
        "sample://second",
        "sample://third",
    ],
])
collection.flush()

collection.create_index(
    field_name="embedding",
    index_params={
        "index_type": "FLAT",
        "metric_type": "L2",
        "params": {},
    },
)
collection.load()

results = collection.search(
    data=[[0.1, 0.2, 0.3, 0.4]],
    anns_field="embedding",
    param={"metric_type": "L2", "params": {}},
    limit=2,
    output_fields=["text", "source"],
)

for hit in results[0]:
    print(hit.id, hit.distance, hit.entity.get("text"), hit.entity.get("source"))
```

정리할 때만 아래 명령을 사용하세요.

```python
collection.release()
# utility.drop_collection("sample_documents")
```

## 5. Notes

- `list_database()` 권한은 제공되지 않습니다. 본인에게 전달된 database 이름으로만 접속하세요.
- collection 이름은 자유롭게 만들 수 있지만, 후보자별 database 안에서 관리해야 합니다.
- 과제 중 큰 데이터를 무제한으로 넣지 말고, 안내된 데이터 크기 제한을 따르세요.
- API key는 개인별 비밀값입니다. GitHub 저장소나 문서에 commit하지 마세요.
- connection 실패 시 host/port, `secure=True`, `db_name`, user/password 오타를 먼저 확인하세요.
