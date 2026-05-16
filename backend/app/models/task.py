"""
app/models/task.py
Table 'tasks'

Pages concernées :
- soignant/tasks.dart (CaregiverAddTasks) :
    sendTasks(), updateTask(), deleteTask()
- patient/patient.dart (PatientPage) :
    streamTasksByDate(), updateTaskStatus()
- SupabaseService.getTaskStyle() :
    type → color + image

Champs JSONB :
- sub_tasks : [{"title": "08:00 Prendre médicament"}]
- status    : {"08:00 Prendre médicament": "green"}
"""
import uuid
from datetime import datetime
from sqlalchemy import String, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID, JSONB
from app.core.database import Base


class Task(Base):
    __tablename__ = "tasks"

    id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), primary_key=True,
        default=lambda: str(uuid.uuid4())
    )

    # ── Lien patient ──────────────────────────────────
    patient_id: Mapped[str] = mapped_column(
        UUID(as_uuid=False),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False, index=True
    )

    # ── Date — streamTasksByDate() ────────────────────
    task_date: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, index=True
    )

    # ── Contenu — sendTasks() ─────────────────────────
    title: Mapped[str] = mapped_column(String(255), nullable=False)

    # 'food' | 'sport' | 'brain' | 'doctor' | 'medicine'
    type: Mapped[str] = mapped_column(String(50), nullable=False)

    # getTaskStyle() : 'orange'|'green'|'lime'|'red'|'indigo'
    color: Mapped[str] = mapped_column(String(50), nullable=True)

    # getTaskStyle() : 'assets/food.png' etc.
    image: Mapped[str] = mapped_column(String(255), nullable=True)

    # [{"title": "08:00 Prendre médicament"}]
    sub_tasks: Mapped[list] = mapped_column(JSONB, default=list)

    # {"08:00 Prendre médicament": "green"|"orange"|"red"}
    # updateTaskStatus() : sub_key = texte sous-tâche, color = couleur
    status: Mapped[dict] = mapped_column(JSONB, default=dict)

    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    # ── Relations ────────────────────────────────────
    patient: Mapped["User"] = relationship(               # noqa
        "User", back_populates="tasks",
        foreign_keys=[patient_id]
    )

    def __repr__(self):
        return f"<Task {self.title} type={self.type} date={self.task_date}>"