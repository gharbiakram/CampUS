from fastapi import APIRouter, HTTPException, status
from ..models.event import Event, EventListResponse

router = APIRouter(
    prefix="/api/events",
    tags=["events"],
)

_DEMO_EVENTS = [
    Event(
        id=1,
        title="Guest Lecture: Mobile Security",
        description="A guest lecture on mobile security best practices.",
        location="Lecture Hall A",
        date="2026-05-10",
        start_time="14:00",
        end_time="15:30",
    ),
    Event(
        id=2,
        title="Hackathon Kickoff",
        description="Start of the 24-hour campus hackathon.",
        location="Innovation Lab",
        date="2026-05-15",
        start_time="09:00",
        end_time="09:30",
    ),
    Event(
        id=3,
        title="Career Fair",
        description="Meet employers and learn about internships.",
        location="Main Atrium",
        date="2026-05-20",
        start_time="10:00",
        end_time="16:00",
    ),
]


@router.get("", response_model=EventListResponse)
async def get_events():
    return EventListResponse(events=_DEMO_EVENTS)


@router.get("/{event_id}", response_model=Event)
async def get_event_by_id(event_id: int):
    for event in _DEMO_EVENTS:
        if event.id == event_id:
            return event

    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Event not found",
    )
