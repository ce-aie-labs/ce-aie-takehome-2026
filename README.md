# AI Engineer Take-Home Assignment

한국 IBM Client Engineering AI Engineer 신입 채용 사전 과제 안내 저장소입니다.

이 저장소는 후보자가 과제를 시작할 때 처음 읽는 문서입니다. 상세 요구사항은
[ASSIGNMENT.md](ASSIGNMENT.md), Milvus 접속 예시는 [MILVUS_USAGE.md](MILVUS_USAGE.md),
starter snippets는 [SKELETON.md](SKELETON.md)를 확인하세요.

## Quick Facts

| 항목 | 내용 |
|---|---|
| 과제 주제 | Multi-Agent, Multi-Tool RAG Assistant on watsonx Orchestrate |
| 진행 기간 | 2026년 5월 27일 (수) 09:00 - 2026년 5월 31일 (일) 23:59 KST |
| 제출 방식 | Private GitHub repository 생성 후 평가자 collaborator 초대, Google Form 제출 |
| 기본 실행 환경 | watsonx Orchestrate SaaS |
| 필수 플랫폼 | watsonx Orchestrate, watsonx.data Milvus Knowledge Base |
| 문의 | Slack Q&A 채널 |

## What To Build

5개 시나리오 중 하나를 골라 고객 페르소나를 위한 RAG assistant를 만듭니다.

최소 구현 범위:

- wxO native supervisor agent 1개와 collaborator agent 2개 이상
- 제공된 watsonx.data Milvus database를 사용하는 Knowledge Base 기반 RAG
- wxO Python tool 2개 이상
- 핵심 사용자 질문 5개와 수동 검증 결과
- RAG와 Python tool을 함께 사용하는 복합 질의 1개 이상
- 평가자가 README만 보고 재현할 수 있는 repository

선택 또는 가산점 범위:

- 핵심 질문 6-7개
- 실제 외부 API 연동
- OpenAPI tool 또는 MCP toolkit
- ADK evaluation CLI 결과
- demo video, slide, retrieval tuning 비교

## Recommended Workflow

1. [ASSIGNMENT.md](ASSIGNMENT.md)를 읽고 시나리오 하나를 고릅니다.
2. 고객 페르소나와 핵심 질문 5개를 먼저 정의합니다.
3. 공개 문서 8-12개를 수집하고 `data/sources.md`에 URL과 라이선스를 적습니다.
4. 문서를 Knowledge Base에 넣고 RAG 답변에 출처가 나오는지 확인합니다.
5. 계산, mock lookup, 외부 API 호출 중 최소 2개 Python tool을 만듭니다.
6. supervisor가 RAG collaborator와 tool collaborator를 호출하도록 agent YAML을 구성합니다.
7. 핵심 질문별 실제 결과, 실패 케이스, 한계를 README에 정리합니다.
8. private GitHub repository를 제출 전 한 번 새 환경에서 재현해 봅니다.

## Submission Checklist

제출 repository에는 최소한 아래 내용이 있어야 합니다.

- `README.md`: 문제 정의, 아키텍처, 실행 방법, 검증 결과, 한계
- `agents/`: supervisor/collaborator YAML 또는 import 가능한 agent 설정
- `tools/python/`: Python tool 코드
- `knowledge_base/` 또는 `rag/`: Knowledge Base 설정과 RAG 설명
- `data/sources.md`: 사용한 문서의 URL과 라이선스
- `docs/validation.md` 또는 README section: 핵심 질문 5개 검증 결과
- `.env.example`: 필요한 환경 변수 placeholder
- AI/code assistant 사용 내역

민감정보는 절대 commit하지 마세요. `.env`, API key, token, password, 개인별 Milvus
password가 포함된 파일은 제출 repository에 들어가면 안 됩니다.

## Documents

- [ASSIGNMENT.md](ASSIGNMENT.md): 공식 과제 요구사항과 평가 기준
- [MILVUS_USAGE.md](MILVUS_USAGE.md): watsonx.data Milvus 접속 정보와 Python sanity check
- [WXAI_USAGE.md](WXAI_USAGE.md): watsonx.ai API key/project ID 확인과 SDK 연결 테스트
- [SKELETON.md](SKELETON.md): agent YAML, Python tool, Knowledge Base starter snippets
- [JD.md](JD.md): 채용 JD 원문

## Evaluation Focus

평가자는 기능의 수보다 아래 항목을 더 중요하게 봅니다.

- 실제로 동작하는 end-to-end 흐름
- 고객 문제를 작은 PoC 범위로 자르는 능력
- RAG, tool, agent routing을 왜 그렇게 설계했는지에 대한 설명
- 출처 인용, 실패 케이스, 한계 분석
- 후속 PT에서 본인이 만든 코드와 결정을 설명하는 능력
