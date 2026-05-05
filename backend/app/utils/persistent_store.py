import json
from pathlib import Path
from threading import Lock


_BASE_DIR = Path(__file__).resolve().parents[1] / 'data_store'
_BASE_DIR.mkdir(parents=True, exist_ok=True)

_LOCK = Lock()


def _path(name: str) -> Path:
    return _BASE_DIR / name


def load_json_list(name: str, default: list[dict]) -> list[dict]:
    path = _path(name)
    if not path.exists():
        save_json_list(name, default)
        return list(default)

    with _LOCK:
        with path.open('r', encoding='utf-8') as handle:
            data = json.load(handle)
            if isinstance(data, list):
                return data

    return list(default)


def save_json_list(name: str, items: list[dict]) -> None:
    path = _path(name)
    with _LOCK:
        with path.open('w', encoding='utf-8') as handle:
            json.dump(items, handle, ensure_ascii=False, indent=2)
