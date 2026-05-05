from pydantic import BaseModel


class TimetableItem(BaseModel):
    id: int
    subject: str
    instructor: str
    day: str
    start_time: str
    end_time: str
    room: str


class TimetableListResponse(BaseModel):
    timetable: list[TimetableItem]
