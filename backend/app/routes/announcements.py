from fastapi import APIRouter, HTTPException, status
from ..models.announcement import Announcement, AnnouncementListResponse

router = APIRouter(
    prefix="/api/announcements",
    tags=["announcements"],
)

_DEMO_ANNOUNCEMENTS = [
    Announcement(
        id=1,
        title="Midterm Exam Schedule Published",
        content="The midterm exam schedule is now available. Please check your department board for room assignments.",
        author="Academic Affairs",
        priority="high",
        created_at="2026-04-19T09:00:00Z",
    ),
    Announcement(
        id=2,
        title="Library Extended Hours",
        content="Main library will remain open until 11:00 PM during exam week.",
        author="Campus Library",
        priority="medium",
        created_at="2026-04-18T13:30:00Z",
    ),
    Announcement(
        id=3,
        title="Parking Lot C Maintenance",
        content="Parking Lot C will be partially closed on Wednesday for line repainting.",
        author="Campus Services",
        priority="low",
        created_at="2026-04-17T07:45:00Z",
    ),
    Announcement(
        id=4,
        title="New Shuttle Route",
        content="A new shuttle route now connects the Engineering Block and Dormitory East every 20 minutes.",
        author="Transportation Office",
        priority="medium",
        created_at="2026-04-16T10:15:00Z",
    ),
    Announcement(
        id=5,
        title="Emergency Drill This Friday",
        content="A campus-wide emergency evacuation drill will take place Friday at 2:00 PM.",
        author="Campus Safety",
        priority="high",
        created_at="2026-04-15T08:20:00Z",
    ),
]


@router.get("", response_model=AnnouncementListResponse)
async def get_announcements():
    return AnnouncementListResponse(announcements=_DEMO_ANNOUNCEMENTS)


@router.get("/{announcement_id}", response_model=Announcement)
async def get_announcement_by_id(announcement_id: int):
    for announcement in _DEMO_ANNOUNCEMENTS:
        if announcement.id == announcement_id:
            return announcement

    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Announcement not found",
    )
