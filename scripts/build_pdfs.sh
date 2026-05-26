#!/usr/bin/env bash
# Build PDFs for tracked Markdown handoff documents using pandoc + xelatex.
# Korean glyphs in code blocks rely on xeCJK (see scripts/pdf-header.tex).

set -eo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

build() {
  local src="$1" out="$2" margin="$3" tocdepth="$4" monoscale="$5"
  local toc_pagebreak="${6:-false}"
  local toc_header=()
  local toc_args=()

  if [[ "$tocdepth" != "0" ]]; then
    toc_args=(-V toc-title="목차" --toc --toc-depth="$tocdepth")
  fi

  if [[ "$toc_pagebreak" == "true" && "$tocdepth" != "0" ]]; then
    toc_header=(-H <(printf '%s\n' \
      '\let\oldtableofcontents\tableofcontents' \
      '\renewcommand{\tableofcontents}{\oldtableofcontents\clearpage}'))
  fi

  echo "[build] $src -> $out"
  pandoc "$src" -o "$out" \
    --pdf-engine=xelatex \
    -H scripts/pdf-header.tex \
    "${toc_header[@]}" \
    -V mainfont="IBM Plex Sans KR" \
    -V monofont="IBM Plex Mono" \
    -V "monofontoptions:Scale=${monoscale}" \
    -V "geometry:margin=${margin}" \
    -V geometry:a4paper \
    -V colorlinks=true -V linkcolor=NavyBlue -V urlcolor=NavyBlue \
    "${toc_args[@]}" \
    --syntax-highlighting=tango \
    2> >(grep -v "Missing character" >&2 || true)
}

build README.md        README.pdf        0.8in 0 0.9
build JD.md            JD.pdf            0.8in 0 0.9
build ASSIGNMENT.md    ASSIGNMENT.pdf    1in   2 0.9  true
build MILVUS_USAGE.md  MILVUS_USAGE.pdf  0.8in 2 0.9  true
build SKELETON.md      SKELETON.pdf      0.8in 2 0.85 true

echo "[done]"
ls -la README.pdf JD.pdf ASSIGNMENT.pdf MILVUS_USAGE.pdf SKELETON.pdf
