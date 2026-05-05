from pydantic import BaseModel


class Event(BaseModel):
    id: int
    title: str
    description: str
    location: str
    date: str
    start_time: str
    end_time: str


class EventListResponse(BaseModel):
    events: list[Event]
