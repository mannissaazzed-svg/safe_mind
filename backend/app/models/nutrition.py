"""
Modèle NutritionAnalysis — enregistrement d'une analyse nutritionnelle.
Correspond aux données saisies dans Flutter HealthAnalysis :
  - âge, poids, taille, pression, glycémie
  - comorbidités (diabète, HTA, dysphagie…)
  - scores calculés (cognitif, moteur, vasculaire, IMC)
  - programme de repas généré
"""
import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class NutritionAnalysis(Base):
    __tablename__ = "nutrition_analyses"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )

   
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        index=True,
    )

    
    disease_type: Mapped[str] = mapped_column(
        String(50), nullable=False
    )  # "Alzheimer" | "Parkinson" | "Alzheimer & Parkinson"

    
    age: Mapped[float] = mapped_column(Float, nullable=False)
    weight: Mapped[int] = mapped_column(Integer, nullable=False)   # kg
    height: Mapped[int] = mapped_column(Integer, nullable=False)   # cm
    pressure: Mapped[float] = mapped_column(Float, nullable=False) # mmHg
    sugar: Mapped[float] = mapped_column(Float, nullable=False)    # mg/dL

    
    has_diabetes: Mapped[bool] = mapped_column(Boolean, default=False)
    has_hta: Mapped[bool] = mapped_column(Boolean, default=False)
    has_dysphagie: Mapped[bool] = mapped_column(Boolean, default=False)
    has_denutrition: Mapped[bool] = mapped_column(Boolean, default=False)
    has_constipation: Mapped[bool] = mapped_column(Boolean, default=False)

    
    has_avc: Mapped[bool] = mapped_column(Boolean, default=False)
    has_depression: Mapped[bool] = mapped_column(Boolean, default=False)
    has_epilepsie: Mapped[bool] = mapped_column(Boolean, default=False)

    
    imc: Mapped[float] = mapped_column(Float, nullable=False)
    imc_label: Mapped[str] = mapped_column(String(50), nullable=False)
    cognitive_score: Mapped[float] = mapped_column(Float, nullable=False)
    motor_score: Mapped[float] = mapped_column(Float, nullable=False)
    vasc_score: Mapped[float] = mapped_column(Float, nullable=False)
    nutrition_score: Mapped[float] = mapped_column(Float, nullable=False)

    
    meal_plan: Mapped[dict] = mapped_column(JSON, default=dict)

    
    tips: Mapped[list] = mapped_column(JSON, default=list)

    
    recommended_foods: Mapped[dict] = mapped_column(JSON, default=dict)
    

    avoided_foods: Mapped[list] = mapped_column(JSON, default=list)
    

   
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    
    user: Mapped["User"] = relationship(  # type: ignore
        "User", back_populates="nutrition_analyses"
    )

    def __repr__(self) -> str:
        return f"<NutritionAnalysis {self.disease_type} IMC={self.imc:.1f} [{self.user_id}]>"