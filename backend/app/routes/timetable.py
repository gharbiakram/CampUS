from fastapi import APIRouter, HTTPException, status
from ..models.timetable import TimetableItem, TimetableListResponse

router = APIRouter(
    prefix="/api/timetable",
    tags=["timetable"],
)

_DEMO_TIMETABLE = [
    TimetableItem(
        id=1,
        subject="Mobile Security",
        instructor="Dr. A. Smith",
        day="Monday",
        start_time="09:00",
        end_time="10:30",
        room="LH1",
    ),
    TimetableItem(
        id=2,
        subject="Software Engineering",
        instructor="Prof. J. Doe",
        day="Tuesday",
        start_time="11:00",
        end_time="12:30",
        room="LH2",
    ),
]


@router.get("", response_model=TimetableListResponse)
async def get_timetable():
    return TimetableListResponse(timetable=_DEMO_TIMETABLE)


@router.get("/{item_id}", response_model=TimetableItem)
async def get_timetable_item(item_id: int):
    for item in _DEMO_TIMETABLE:
        if item.id == item_id:
            return item
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Timetable item not found",
    )
