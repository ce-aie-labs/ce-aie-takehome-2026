# [한국 IBM Client Engineering] AI Engineer 신입 채용 사전 과제

## Multi-Agent, Multi-Tool RAG Assistant on watsonx Orchestrate

> - **과제 진행 기간:** 2026년 5월 27일 (수) 09:00 - 2026년 5월 31일 (일) 23:59 (KST)
> - **제출 마감:** 2026년 5월 31일 (일) 23:59 (KST)
> - **제출 방식:** Private GitHub repository 생성 후 평가자 collaborator 초대, Slack 채널에 공지되는 Google Form으로 제출
> - **Q&A:** 과제 시작 전 Slack 채널 초대 예정
> - **사용 언어:** 코드/식별자/커밋 메시지는 영문, README와 리포트는 국문 또는 영문

---

## 1. 응시자 안내

본 과제는 실무 면접 이후 진행되는 후속 기술 검증 및 PT의 핵심 자료로 사용됩니다. 구현 결과뿐 아니라 문제 정의, 의사결정 근거, 결과 전달력도 함께 평가합니다.

정답이 하나인 과제가 아닙니다. 수집한 정보와 구현 결과를 바탕으로 본인이 어떤 가정을 세웠고, 어떤 trade-off를 선택했으며, 무엇을 검증했는지 명확히 설명해 주세요.

생성형 AI 및 code assistant 도구 사용은 가능합니다. 단, 사용한 도구, 요금제/환경, 도움받은 범위를 README에 명시해야 합니다. 도구가 생성한 코드도 최종 책임은 지원자에게 있으며, 후속 PT에서는 본인이 제출한 코드와 설계 결정을 설명할 수 있어야 합니다.

본 과제 문서와 제공 자료, Slack 안내, 제공 환경 정보, 후속 면접에서 다루는 내용은 한국 IBM 채용 전형 평가 목적으로만 제공됩니다. 과제 및 면접 관련 내용을 외부에 유출하거나 타인과 공유하지 마세요.

---

## 2. 과제 목표와 범위

Client Engineering의 AI Engineer는 고객사 도메인을 빠르게 학습하고, **IBM watsonx Orchestrate(이하 wxO)** 위에 PoC를 며칠 안에 올려 비즈니스 가치를 증명하는 역할입니다.

본 과제에서는 아래 5개 시나리오 중 하나를 선택하여 해당 고객 페르소나를 위한 **Multi-Agent Assistant**를 wxO 위에 구축합니다.

### 2.1 최소 구현 범위

아래 항목은 반드시 충족해야 합니다.

- 시나리오 A-E 중 하나 선택
- 공개 문서 8-12개 수집 및 출처/라이선스 정리
- Supervisor agent 1개와 collaborator agent 2개 이상 구성
- 제공된 watsonx.data Milvus database를 external vector index로 연결한 wxO Knowledge Base RAG
- Python tool 2개 이상 구현
- 핵심 사용자 질문 5개 정의 및 수동 검증
- RAG와 Python tool을 함께 사용하는 복합 질의 1개 이상
- 답변 불가 질의 1개에서 환각 대신 한계와 대안 제시
- README만 보고 평가자가 기본 데모를 재현할 수 있는 repository 구성

---

## 3. 시나리오 선택

아래 5개 시나리오 중 하나를 선택하세요. 시나리오 선택 자체로 유불리가 생기지 않도록 평가합니다. 도메인 전문성 자체는 평가 대상이 아니며, 선택한 범위 안에서 문제를 적절히 좁히고 근거 기반으로 설계, 구현, 평가했는지를 봅니다.

| # | 시나리오 | 고객 페르소나 | 해결해야 할 문제 | 추천 공개 데이터 | 추천 Tool 예시 |
|---|---|---|---|---|---|
| A | **금융 상품/공시 어시스턴트** | 은행 디지털채널 담당자 | 금융 상품 약관, 기업 공시, 금리/환율 정보를 근거와 함께 빠르게 확인 | 금감원 DART 공시, 한국은행 ECOS, 은행/카드/보험 공개 약관 | 환율 조회, 금리 조회, 대출 상환액 계산 |
| B | **제조/에너지 운영 분석 어시스턴트** | 제조사 생산기술팀 엔지니어 | 설비 운영, 에너지 사용, 안전 기준 관련 문서를 검색하고 운영 지표를 계산 | 제조사 ESG 리포트/IR, 산업안전보건공단 자료, KS/ISO 공개 자료 | OEE 계산, 에너지 사용량 계산, 부품 재고 mock 조회 |
| C | **통신 요금제/고객 문의 어시스턴트** | 통신사 CX 운영팀 | 고객 조건에 맞는 요금제/정책을 찾고 장애/청구 문의를 구조화해 응답 | 통신사 공개 약관/요금제, 방통위 보고서, 통신 품질 공개 자료 | 요금제 추천, 예상 요금 계산, 장애 지역 mock 조회 |
| D | **리테일 배송/반품/재고 운영 어시스턴트** | 이커머스/리테일 운영 매니저 | 배송, 반품, 재고, 프로모션 정책을 근거 기반으로 안내하고 운영 판단 지원 | 이커머스 공개 정책, 통계청 도소매 통계, 공정위 자료 | 재고 mock 조회, 배송 상태 조회, 할인/마진 계산 |
| E | **공공/보건/복지 민원 어시스턴트** | 지자체 민원 응대 담당자 | 민원인이 묻는 제도, 보건/복지 안내, 공공 데이터 위치를 출처와 함께 안내 | 공공데이터포털, 보건복지부/식약처 공개 가이드, 지자체 공개 자료 | 공공데이터 검색, 의약품 정보 조회, 공휴일 조회 |

---

## 4. 데이터와 사용자 질문

문서는 직접 선정합니다. 데이터를 찾고 정제하는 능력도 평가 대상입니다.

문서 조건:

- 공개 문서 8-12개
- 공개 데이터 또는 재사용 가능한 공개 자료만 사용
- 개인정보, 유료 자료, 저작권 이슈가 있는 자료 금지
- 한국어 80% 이상
- PDF, HTML, 표가 포함된 문서 등 형식 혼합 권장
- 각 문서의 출처 URL과 라이선스/이용 조건을 `data/sources.md` 또는 README에 기재

선택한 시나리오의 고객 페르소나가 자주 묻는 **핵심 질문 5개**를 README 첫 페이지에 정의하세요. 만능 에이전트를 만들기보다, 정의한 질문을 안정적으로 처리하는 데 집중하세요. 시간이 남으면 6-7개까지 확장할 수 있습니다.

핵심 질문 5개에는 아래 4가지 유형이 모두 포함되어야 합니다.

1. **단순 사실 질의**: RAG로 문서에서 근거와 출처 인용
2. **외부 시스템 호출 질의**: Python tool을 호출해 계산값, mock 데이터, API 결과 등 구조화 데이터 반환
3. **복합 질의**: RAG 결과와 Python tool 결과를 함께 사용
4. **답변 불가 질의**: 환각 대신 모르는 이유와 확인 가능한 대안 제시

추가 조건:

- 5개 질문 중 최소 2개 이상은 watsonx.data Milvus external vector index를 연결한 Knowledge Base에서 문서를 검색해야 합니다.
- 5개 질문 중 최소 1개 이상은 Python tool 결과를 사용해야 합니다.
- 5개 질문 중 최소 1개 이상은 RAG 결과와 Python tool 결과를 함께 사용해야 합니다.
- RAG는 약관, 정책, 공시, 리포트, 가이드처럼 문서 근거가 필요한 질문에 사용하세요.
- Tool은 계산, 구조화 조회, mock 데이터 조회, 외부 API 호출처럼 입력/출력이 분명한 작업에 사용하세요.

외부 API 연동이 어렵거나 API key 발급이 필요한 경우, CSV/JSON mock 데이터를 포함한 Python tool로 대체해도 됩니다. 실제 API 사용 여부보다 tool이 문제 해결에 적합한지, 입력/출력 schema와 가정/한계를 README에 명확히 적었는지를 평가합니다.

---

## 5. 기술 요구사항

### 5.1 Multi-Agent 구성

- wxO Native Agent 3개 이상
- Supervisor agent 1개 + collaborator agent 2개 이상
- Supervisor는 `style: react` 권장
- Collaborator는 `style: default` 권장
- Collaborator의 역할이 명확해야 하며, supervisor의 `description`이 routing에 사용됨을 고려해 작성

Supervisor YAML 예시:

```yaml
spec_version: v1
kind: native
name: scenario_supervisor
llm: groq/openai/gpt-oss-120b
style: react
description: |
  Supervisor for <scenario> assistant. Routes to specialist collaborators.
collaborators:
  - rag_specialist_agent
  - data_lookup_agent
```

### 5.2 Python Tool 구성

wxO Python tool을 총 2개 이상 구현하세요. OpenAPI와 MCP는 필수가 아닙니다.

필수 조건:

- 최소 1개 이상은 계산, 구조화 조회, CSV/JSON mock 데이터 조회, 외부 API 호출 등 **비-RAG business tool**이어야 합니다.
- Tool 함수의 입력/출력, 가정, 오류 처리 방식을 README에 설명합니다.
- Milvus 기반 RAG는 별도 Python retrieval tool로 직접 구현하지 않아도 됩니다.
- Knowledge Base 기반 RAG 구성은 Python tool 개수와 별개로 봅니다.

### 5.3 RAG - watsonx.data Milvus 연동

본 과제에서 말하는 wxO Knowledge Base는 wxO가 문서를 직접 업로드받아 자체 built-in index를 만드는 방식이 아니라, IBM이 제공하는 **watsonx.data Milvus database를 external vector index로 연결하는 방식**을 의미합니다.

이렇게 분리하는 이유는 후보자가 문서 전처리, chunking, embedding 모델, Milvus collection schema, metadata를 직접 설계하고 설명할 수 있게 하기 위함입니다. wxO built-in document upload Knowledge Base는 전처리와 embedding/index 설정을 세밀하게 통제하기 어렵기 때문에, 최종 제출의 필수 RAG 요건으로 인정하지 않습니다.

- 수집한 문서 8-12개를 전처리하고, 안내된 방식에 따라 지원자별로 분리 제공되는 watsonx.data Milvus database를 Knowledge Base에 연결해 사용합니다.
- chunk text, embedding vector, source URL, page/chunk id 등 metadata를 포함한 collection을 직접 생성/적재합니다.
- Milvus database는 지원자별로 분리 제공되므로 다른 지원자의 데이터를 조회할 수 없습니다.
- wxO agent는 Knowledge Base를 통해 external Milvus 검색 결과를 받아 답변에 사용합니다.
- Milvus 검색을 위한 별도 Python retrieval tool 구현은 필수가 아닙니다.
- 답변에는 출처(파일명, URL, 페이지 또는 chunk id)가 포함되도록 agent instructions에 명시하세요.

RAG 구현 설명에는 다음이 포함되어야 합니다.

- 문서 전처리와 chunk 생성 방식
- Milvus collection schema와 wxO external Knowledge Base 설정
- embedding 모델 선택 근거
- retrieval query, `top_k`, score 사용 방식
- 검색 결과의 source metadata

Milvus 접속 정보, API key, password 등 민감정보는 repository에 commit하지 마세요. `.env`, credential 파일, token이 포함된 설정 파일을 올리면 GitHub 또는 사내 secret scanning 경고가 발생할 수 있으며, 평가에도 불리하게 반영될 수 있습니다. 필요한 값은 `.env.example` 또는 README의 placeholder로만 설명하세요.

---

## 6. 실행 환경

### 6.1 기본 환경

- 본 과제에서 제공하는 기본 실행 환경은 **watsonx Orchestrate SaaS**입니다.
- IBM이 TechZone 예약 링크로 watsonx Orchestrate SaaS 인스턴스를 공유합니다.
- 별도 로컬 서버/컨테이너 설치는 필요하지 않습니다.
- 본인 PC에는 ADK CLI(`orchestrate`)만 설치하고, 공유받은 인스턴스에 환경을 등록/활성화합니다.

```bash
python -m pip install --upgrade "ibm-watsonx-orchestrate[agentops]"
orchestrate env add --name my-env --url <SHARED_INSTANCE_URL>
orchestrate env activate my-env --api-key <SHARED_API_KEY>
orchestrate env list
```

테스트 UI는 watsonx Orchestrate SaaS 웹 콘솔의 chat/preview 화면을 사용합니다. 인증 토큰은 약 2시간마다 만료될 수 있으므로, 만료 시 `orchestrate env activate`를 다시 실행하세요.

### 6.2 LLM 모델

- 권장 모델: `groq/openai/gpt-oss-120b`
- 필요 시 사용 가능한 대체 모델은 Slack 또는 과제 안내에서 공유합니다.
- 실제 사용 가능한 모델은 `orchestrate models list`에서 확인하세요.
- 모델 선택 근거를 README에 1줄 작성하세요.

### 6.3 IBM 제공

- 제출한 IBMid 기준 watsonx Orchestrate SaaS 환경 접근 권한
- TechZone 예약 링크로 공유되는 watsonx Orchestrate SaaS 인스턴스
- 지원자별로 분리된 watsonx.data Milvus database 접속 정보와 사용 가이드
- 과제 시작 전 Slack 채널 초대 및 과제 기간 중 Q&A 운영

### 6.4 지원자 준비

- 본인 PC
- Python 3.11+ (설치 이슈가 있으면 Python 3.12 권장)
- GitHub 계정
- IBMid

IBMid가 없는 경우 IBM 공식 가이드에 따라 계정을 생성하세요.

- IBMid 생성 가이드: https://www.ibm.com/docs/en/storage-defender/base?topic=in-creating-ibmid

---

## 7. 제출물

하나의 **private GitHub repository**로 제출합니다. 제출 전 안내받은 평가자 GitHub 계정을 repository collaborator로 초대해 주세요.

최종 제출은 Slack 채널에 공지되는 Google Form을 통해 진행합니다. GitHub repository URL만 Slack DM이나 이메일로 제출하지 마세요.

필수 포함 내용:

- README
- 후속 PT용 발표 자료 PDF (`demo/slide.pdf`)
- agent YAML 또는 agent import에 필요한 설정 파일
- Python tool 코드
- 선택한 문서 목록과 출처/라이선스 정보
- 핵심 질문 5개와 수동 검증 결과
- 실행/재현 스크립트 또는 명령어
- 데모 설명 (`demo.md` 권장)

Repository 구조는 자유롭게 정해도 됩니다. 아래는 예시입니다.

```text
<your-repo>/
├── README.md
├── ARCHITECTURE.md
├── agents/
├── tools/
│   └── python/
├── knowledge_base/
│   └── kb.yaml
├── data/
│   └── sources.md
├── docs/
│   ├── test-questions.md
│   └── validation.md
├── evaluations/       # 선택
├── scripts/
└── demo/
    ├── demo.md        # 권장
    ├── demo.mp4       # 선택
    └── slide.pdf      # 필수
```

### 7.1 README 필수 항목

1. 선택한 시나리오, 고객 페르소나, 핵심 사용자 질문 5개
2. 아키텍처 한 장 요약: supervisor, collaborator, tool, RAG 관계
3. 재현 가이드: `git clone`부터 wxO SaaS 웹 콘솔에서 agent 테스트까지 15분 안에 따라할 수 있어야 함
4. 기술 선택의 근거
   - LLM 모델
   - supervisor `react` style
   - collaborator `default` style
   - 임베딩 모델
   - chunking 전략
   - watsonx.data Milvus external Knowledge Base/retrieval 전략
5. 수동 검증 결과 요약: 핵심 질문별 기대 동작/실제 결과, 실패 또는 한계 1개
6. 알려진 한계와 다음 단계
7. 사용한 외부 자료/AI/code assistant 도구
   - 예: `Codex Pro $100 plan`, `Claude Code Max $200 plan`, `ChatGPT Plus`, `GitHub Copilot Business`, `Cursor Pro`
   - 도움받은 범위: 아이디어 정리, 코드 생성, 디버깅, 문서 작성, 테스트 작성, 리팩터링, 오류 원인 분석 등
8. 결과 전달 요약: 고객 문제, 구현 결과, 검증 결과, 한계와 다음 액션

### 7.2 Google Form 제출 정보

| 항목 | 필수 여부 | 설명 |
|---|---|---|
| 이름 | 필수 | 지원자 이름 |
| 이메일 | 필수 | 채용 전형에서 사용하는 이메일 |
| IBMid 이메일 | 필수 | watsonx Orchestrate SaaS 접근 권한을 받은 IBMid |
| GitHub repository URL | 필수 | 최종 제출 private repository URL |
| 평가자 collaborator 초대 여부 | 필수 | 안내받은 평가자 GitHub 계정을 collaborator로 초대했는지 확인 |
| 선택 시나리오 | 필수 | A-E 중 선택한 시나리오명 |
| AI/code assistant 사용 내역 | 필수 | 사용한 도구명, 요금제/환경, 도움받은 범위 |
| 발표 자료 파일 경로 | 필수 | repository에 포함한 발표 자료 PDF 경로. 기본값: `demo/slide.pdf` |
| PT 요약 | 필수 | 아래 4개 항목을 짧게 작성 |
| 기타 참고 사항 | 선택 | 평가자가 알아야 할 제약, 미완성 부분, 환경 이슈 |

PT 요약은 아래 4가지만 짧게 작성하세요.

- 고객 문제 한 줄 요약
- 핵심 설계 결정 1개
- 가장 중요한 실패/한계 1개
- 다음 개선 방향 1개

제출 마감 시점은 Google Form 제출 timestamp를 기준으로 판단합니다. 제출 후 repository를 수정해야 하는 경우 Slack 채널에 수정 사유와 변경 내용을 알려주세요.

---

## 8. 데모 및 후속 PT

데모 영상 제출은 필수가 아닙니다. 후속 면접 당일 live demo로 대체할 수 있습니다. 다만 평가자가 사전에 흐름을 이해할 수 있도록 `demo.md`에 핵심 데모 시나리오와 확인 포인트를 적는 것을 권장합니다.

데모 영상 또는 live demo에서 보여줄 것:

- watsonx Orchestrate SaaS 웹 콘솔에서 supervisor에 자연어 질의
- Supervisor가 collaborator를 호출하는 reasoning trace
- RAG 답변과 출처 인용
- Python tool 호출 결과
- 실패 케이스 1개와 원인 진단

후속 면접에서는 과제 결과를 기반으로 PT 및 기술 Q&A를 진행할 예정입니다. 발표 자료 제출은 필수이며, repository에 `demo/slide.pdf` 형태의 PDF 파일로 포함하세요.

PT 진행 시간과 세부 방식은 후속 면접 안내를 우선합니다. 일반적으로는 50분 내외로 진행하며, 과제 결과 발표 15분과 질의응답 35분을 기준으로 준비하면 됩니다. 발표 자료는 제목 포함 5장 이내를 권장합니다.

PT에서는 다음 내용을 설명할 수 있어야 합니다.

- 고객 페르소나와 해결하려는 문제
- 전체 아키텍처와 핵심 의사결정
- 대표 시나리오 1-2개 데모 결과
- 검증 결과와 실패/한계
- 실제 고객 PoC 또는 운영 환경으로 확장할 때 필요한 다음 단계

코드 한 줄 한 줄의 의미를 모두 세세히 설명할 필요는 없지만, **자신이 내린 결정의 이유와 그 결정이 고객 문제 해결에 어떤 의미가 있는지는 설명할 수 있어야** 합니다.

---

## 9. 평가 기준

### 9.1 평가 원칙

평가자는 다음 질문에 답할 수 있는지를 중심으로 봅니다.

1. 실제로 동작하는가, 그리고 구조가 요구사항에 맞게 합리적으로 설계되었는가?
2. 결과가 맞는지 확인하기 위한 평가 기준과 실패 분석을 스스로 만들었는가?
3. 고객 문제를 명시적 가정, KPI, 가설, 기대 ROI로 좁혀 설명할 수 있는가?
4. 모호한 요구사항을 그대로 두지 않고 PoC 범위로 잘 자르고 trade-off를 설명할 수 있는가?
5. 후속 PT와 Q&A에서 시간을 지키고, 고객이 이해할 수 있는 언어로 전달할 수 있는가?
6. 처음 접하는 IBM 제품과 새 스택을 요구사항에 맞게 빠르게 학습하고 근거 있게 선택했는가?

### 9.2 최소 통과 조건

아래 항목 중 하나라도 충족하지 못하면 고득점이 어렵습니다.

- README의 실행 절차로 기본 데모가 재현된다.
- Supervisor agent가 최소 2개 collaborator 중 하나 이상을 실제로 호출한다.
- 최소 2개 질의에서 external Milvus Knowledge Base 기반 RAG 답변과 출처가 함께 제시된다.
- 최소 1개 질의에서 Python tool 호출 결과가 답변에 반영된다.
- 최소 1개 질의에서 RAG 결과와 Python tool 결과가 함께 사용된다.
- 5개 핵심 질문에 대한 수동 동작 확인 결과가 제출된다.
- 실패 케이스 1건 이상에 대해 원인과 개선 방향을 작성한다.
- 고객 문제, 주요 가정, 기대 KPI 또는 성공 기준을 README에 명시한다.
- 후속 PT에서 본인이 내린 주요 기술 의사결정을 설명할 수 있다.

### 9.3 점수 배점

| 영역 | 비중 | 평가 포인트 |
|---|---:|---|
| **기술적 완성도** | 40% | 실제 동작 여부, agent/tool/RAG 아키텍처 합리성, 평가까지 고려한 설계, end-to-end 재현 가능성 |
| **Business Acumen** | 25% | 문제 정의, KPI, 가설, 기대 ROI 제시, 모호한 요구사항을 명시적 가정과 PoC 범위로 좁히는 능력 |
| **발표 & Q&A** | 20% | 시간관리, 고객 커뮤니케이션, 자료 가독성, trade-off 설명, 모르는 것을 인정하는 솔직함, 압박 질문에서 가정을 재검토하는 능력 |
| **학습력** | 15% | 제시된 IBM 제품 이해와 활용, 요구사항에 맞는 기능 선택, 근거 있는 새 스택 시도와 학습 과정 설명 |

---

## 10. FAQ

**Q1. 본인 PC 사양이 어느 정도 필요한가요?**

ADK CLI(`orchestrate`)와 IDE만 동작하면 충분합니다. watsonx Orchestrate SaaS, watsonx.data Milvus, LLM 추론 환경은 안내된 공유 환경 기준으로 제공되므로 일반 노트북이면 됩니다.

**Q2. wxO Knowledge Base를 사용해도 되나요?**

네. 단, 최종 제출의 필수 RAG 요건은 wxO built-in document upload Knowledge Base가 아니라, 지원자별로 분리 제공되는 watsonx.data Milvus database를 external vector index로 연결한 Knowledge Base입니다.

**Q3. OpenAPI나 MCP를 꼭 써야 하나요?**

아니요. 필수 요건은 Python tool만으로 충족할 수 있습니다. OpenAPI tool 또는 MCP toolkit은 필수가 아닙니다.

**Q4. 영문 README가 필수인가요?**

국문 허용. 단 코드 식별자와 커밋 메시지는 영문으로 작성하세요.

**Q5. 데모 영상 대신 live demo로 대체할 수 있나요?**

네. 데모 영상은 필수가 아니며, 후속 면접 당일 live demo로 대체할 수 있습니다. 다만 사전 평가자가 흐름을 이해할 수 있도록 repository에 `demo.md` 또는 간단한 스크린샷/설명을 남기는 것을 권장합니다.

**Q6. PT는 어떻게 준비하면 되나요?**

기능을 많이 나열하기보다, 고객 문제 -> 설계 선택 -> 구현 결과 -> 검증 결과 -> 실패와 다음 액션의 흐름으로 설명할 수 있게 준비하세요. 발표 자료 PDF 제출은 필수이며, 후속 PT 또는 기술 Q&A는 제출한 repository, demo, validation 문서, 발표 자료, Google Form의 PT 요약을 기반으로 진행합니다.

---

## 11. 참고 자료

- IBM watsonx Orchestrate ADK 공식 문서: https://developer.watson-orchestrate.ibm.com/
- IBM watsonx Orchestrate product documentation: https://www.ibm.com/docs/en/watsonx/watson-orchestrate/base?topic=getting-started-watsonx-orchestrate
- IBM watsonx Orchestrate ADK GitHub examples: https://github.com/IBM/ibm-watsonx-orchestrate-adk/tree/main/examples
- IBMid 생성 가이드: https://www.ibm.com/docs/en/storage-defender/base?topic=in-creating-ibmid

---

담당자 이메일: kiyeon.jeon@ibm.com
