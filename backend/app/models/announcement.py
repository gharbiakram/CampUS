from pydantic import BaseModel


class Announcement(BaseModel):
    id: int
    title: str
    content: str
    author: str
    priority: str
    created_at: str


class AnnouncementListResponse(BaseModel):
    announcements: list[Announcement]
