from __future__ import annotations

from pathlib import Path


OUTPUT_PDF = Path(__file__).with_name("SmartCampus_Progress_Report.pdf")
SOURCE_MD = Path(__file__).with_name("SmartCampus_Progress_Report.md")


def _escape_pdf_text(text: str) -> str:
    return text.replace("\\", r"\\").replace("(", r"\(").replace(")", r"\)")


def _wrap_lines(text: str, max_chars: int = 90) -> list[str]:
    lines: list[str] = []
    for paragraph in text.splitlines():
        if not paragraph:
            lines.append("")
            continue
        current = ""
        for word in paragraph.split():
            candidate = word if not current else f"{current} {word}"
            if len(candidate) > max_chars and current:
                lines.append(current)
                current = word
            else:
                current = candidate
        if current:
            lines.append(current)
    return lines


def _build_pdf_lines() -> list[str]:
    text = SOURCE_MD.read_text(encoding="utf-8")
    return _wrap_lines(text, max_chars=92)


def _write_pdf(lines: list[str]) -> None:
    header = "%PDF-1.4\n"
    objects: list[bytes] = []

    def add_object(content: str) -> int:
        objects.append(content.encode("latin-1"))
        return len(objects)

    font_obj = add_object("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")

    page_contents: list[int] = []
    pages: list[int] = []

    lines_per_page = 42
    chunks = [lines[i : i + lines_per_page] for i in range(0, len(lines), lines_per_page)] or [[""]]

    for chunk in chunks:
        content_lines = ["BT", "/F1 11 Tf", "72 760 Td"]
        first = True
        for line in chunk:
            escaped = _escape_pdf_text(line)
            if first:
                content_lines.append(f"({escaped}) Tj")
                first = False
            else:
                content_lines.append("T*")
                content_lines.append(f"({escaped}) Tj")
        content_lines.append("ET")
        stream = "\n".join(content_lines)
        content_obj = add_object(f"<< /Length {len(stream.encode('latin-1'))} >>\nstream\n{stream}\nendstream")
        page_contents.append(content_obj)

    page_obj_indices: list[int] = []
    for content_obj in page_contents:
        page_obj = add_object(
            f"<< /Type /Page /Parent 0 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 {font_obj} 0 R >> >> /Contents {content_obj} 0 R >>"
        )
        page_obj_indices.append(page_obj)

    pages_obj_index_placeholder = len(objects) + 1
    kids = " ".join(f"{obj} 0 R" for obj in page_obj_indices)
    pages_obj = add_object(f"<< /Type /Pages /Kids [{kids}] /Count {len(page_obj_indices)} >>")
    catalog_obj = add_object(f"<< /Type /Catalog /Pages {pages_obj} 0 R >>")

    # Fix each page's parent reference now that pages object exists.
    fixed_objects: list[bytes] = []
    for index, content in enumerate(objects, start=1):
        if index in page_obj_indices:
            fixed_objects.append(
                f"<< /Type /Page /Parent {pages_obj} 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 {font_obj} 0 R >> >> /Contents {page_contents[page_obj_indices.index(index)]} 0 R >>".encode(
                    "latin-1"
                )
            )
        else:
            fixed_objects.append(content)

    # Replace the placeholder page objects with fixed versions.
    objects[:] = fixed_objects

    pdf = bytearray()
    pdf.extend(header.encode("latin-1"))

    offsets = [0]
    for i, obj in enumerate(objects, start=1):
        offsets.append(len(pdf))
        pdf.extend(f"{i} 0 obj\n".encode("latin-1"))
        pdf.extend(obj)
        pdf.extend(b"\nendobj\n")

    xref_pos = len(pdf)
    pdf.extend(f"xref\n0 {len(objects)+1}\n".encode("latin-1"))
    pdf.extend(b"0000000000 65535 f \n")
    for offset in offsets[1:]:
        pdf.extend(f"{offset:010d} 00000 n \n".encode("latin-1"))

    pdf.extend(
        f"trailer\n<< /Size {len(objects)+1} /Root {catalog_obj} 0 R >>\nstartxref\n{xref_pos}\n%%EOF\n".encode(
            "latin-1"
        )
    )

    OUTPUT_PDF.write_bytes(pdf)


def main() -> None:
    lines = _build_pdf_lines()
    _write_pdf(lines)
    print(f"Wrote {OUTPUT_PDF}")


if __name__ == "__main__":
    main()
