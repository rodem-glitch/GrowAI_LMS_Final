// 왜 필요한가:
// - "엑셀 다운로드" 버튼이 실제로 파일을 내려줘야, 운영자가 데이터를 바로 확인/공유할 수 있습니다.
// - 서버에 새 다운로드 API를 추가하지 않아도, 현재 화면에 있는 목록 데이터를 CSV로 내려보낼 수 있습니다.

export type CsvCell = string | number | boolean | null | undefined;

function escapeCsvCell(value: CsvCell) {
  if (value === null || value === undefined) return '';
  const raw = String(value);
  const needsQuote = /[",\r\n]/.test(raw);
  const escaped = raw.replace(/"/g, '""');
  return needsQuote ? `"${escaped}"` : escaped;
}

export function buildCsv(headers: string[], rows: CsvCell[][]) {
  const lines: string[] = [];
  lines.push(headers.map(escapeCsvCell).join(','));
  rows.forEach((row) => {
    lines.push(row.map(escapeCsvCell).join(','));
  });
  return lines.join('\r\n');
}

export function downloadCsv(filename: string, headers: string[], rows: CsvCell[][]) {
  // 왜: 엑셀에서 한글이 깨지는 것을 줄이기 위해 UTF-8 BOM을 붙입니다.
  const csv = `\ufeff${buildCsv(headers, rows)}`;
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);

  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

