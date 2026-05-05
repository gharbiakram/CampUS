from fastapi import APIRouter, HTTPException, status

from ..models.timetable import TimetableItem, TimetableListResponse
from ..utils.persistent_store import load_json_list, save_json_list

router = APIRouter(
    prefix="/api/timetable",
    tags=["timetable"],
)

_STORAGE_FILE = 'timetable.json'
_DEFAULT_TIMETABLE = [
    {
        'id': 1,
        'subject': 'Mobile Security',
        'instructor': 'Dr. A. Smith',
        'day': 'Monday',
        'start_time': '09:00',
        'end_time': '10:30',
        'room': 'LH1',
    },
    {
        'id': 2,
        'subject': 'Software Engineering',
        'instructor': 'Prof. J. Doe',
        'day': 'Tuesday',
        'start_time': '11:00',
        'end_time': '12:30',
        'room': 'LH2',
    },
]


def _load_timetable() -> list[TimetableItem]:
    return [TimetableItem(**item) for item in load_json_list(_STORAGE_FILE, _DEFAULT_TIMETABLE)]


def _persist_timetable() -> None:
    save_json_list(_STORAGE_FILE, [item.dict() for item in _DEMO_TIMETABLE])


_DEMO_TIMETABLE = _load_timetable()


def _next_id() -> int:
    return max((item.id for item in _DEMO_TIMETABLE), default=0) + 1


@router.get("", response_model=TimetableListResponse)
async def get_timetable():
    return TimetableListResponse(timetable=_DEMO_TIMETABLE)


@router.post("", response_model=TimetableItem, status_code=status.HTTP_201_CREATED)
async def create_timetable_item(item: TimetableItem):
    stored = TimetableItem(
        id=item.id or _next_id(),
        subject=item.subject,
        instructor=item.instructor,
        day=item.day,
        start_time=item.start_time,
        end_time=item.end_time,
        room=item.room,
    )
    _DEMO_TIMETABLE.append(stored)
    _persist_timetable()
    return stored


@router.get("/{item_id}", response_model=TimetableItem)
async def get_timetable_item(item_id: int):
    for item in _DEMO_TIMETABLE:
        if item.id == item_id:
            return item
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Timetable item not found",
    )
