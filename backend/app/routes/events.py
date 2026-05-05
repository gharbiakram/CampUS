from fastapi import APIRouter, HTTPException, status

from ..models.event import Event, EventListResponse
from ..utils.persistent_store import load_json_list, save_json_list

router = APIRouter(
    prefix="/api/events",
    tags=["events"],
)

_STORAGE_FILE = 'events.json'
_DEFAULT_EVENTS = [
    {
        'id': 1,
        'title': 'Guest Lecture: Mobile Security',
        'description': 'A guest lecture on mobile security best practices.',
        'location': 'Lecture Hall A',
        'date': '2026-05-10',
        'start_time': '14:00',
        'end_time': '15:30',
    },
    {
        'id': 2,
        'title': 'Hackathon Kickoff',
        'description': 'Start of the 24-hour campus hackathon.',
        'location': 'Innovation Lab',
        'date': '2026-05-15',
        'start_time': '09:00',
        'end_time': '09:30',
    },
    {
        'id': 3,
        'title': 'Career Fair',
        'description': 'Meet employers and learn about internships.',
        'location': 'Main Atrium',
        'date': '2026-05-20',
        'start_time': '10:00',
        'end_time': '16:00',
    },
]


def _load_events() -> list[Event]:
    return [Event(**item) for item in load_json_list(_STORAGE_FILE, _DEFAULT_EVENTS)]


def _persist_events() -> None:
    save_json_list(_STORAGE_FILE, [event.dict() for event in _DEMO_EVENTS])


_DEMO_EVENTS = _load_events()


def _next_id() -> int:
    return max((event.id for event in _DEMO_EVENTS), default=0) + 1


@router.get("", response_model=EventListResponse)
async def get_events():
    return EventListResponse(events=_DEMO_EVENTS)


@router.post("", response_model=Event, status_code=status.HTTP_201_CREATED)
async def create_event(event: Event):
    stored = Event(
        id=event.id or _next_id(),
        title=event.title,
        description=event.description,
        location=event.location,
        date=event.date,
        start_time=event.start_time,
        end_time=event.end_time,
    )
    _DEMO_EVENTS.append(stored)
    _persist_events()
    return stored


@router.get("/{event_id}", response_model=Event)
async def get_event_by_id(event_id: int):
    for event in _DEMO_EVENTS:
        if event.id == event_id:
            return event

    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Event not found",
    )
