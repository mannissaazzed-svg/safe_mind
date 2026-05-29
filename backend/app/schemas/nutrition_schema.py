"""
Schémas Pydantic — Nutrition Analysis.
Correspondent exactement aux données de la page Flutter HealthAnalysis.
"""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any, Literal, Optional

from pydantic import BaseModel, Field




class ComorbiditiesIn(BaseModel):
    has_diabetes: bool = False
    has_hta: bool = False
    has_dysphagie: bool = False
    has_denutrition: bool = False
    has_constipation: bool = False
    # Alzheimer / Both only
    has_avc: bool = False
    has_depression: bool = False
    has_epilepsie: bool = False



class NutritionAnalysisIn(BaseModel):
    """
    Données envoyées par Flutter HealthAnalysis après clic sur ANALYSER.
    Le backend recalcule les scores et génère le programme.
    """
    disease_type: Literal["Alzheimer", "Parkinson", "Alzheimer & Parkinson"]

    # Anthropométrie
    age: float = Field(ge=40, le=100)
    weight: int = Field(ge=30, le=150)   # kg
    height: int = Field(ge=100, le=220)  # cm

    
    pressure: float = Field(ge=60, le=200)   # mmHg
    sugar: float = Field(ge=40, le=300)      # mg/dL

    
    comorbidities: ComorbiditiesIn = Field(default_factory=ComorbiditiesIn)

    
    notes: Optional[str] = None




class NutritionScoresOut(BaseModel):
    imc: float
    imc_label: str
    cognitive_score: float
    motor_score: float
    vasc_score: float
    nutrition_score: float     


class FoodItem(BaseModel):
    url: str
    title: str
    desc: str


class MealPlanOut(BaseModel):
    petit_dejeuner: str = Field(alias="Petit déjeuner")
    collation: str = Field(alias="Collation")
    dejeuner: str = Field(alias="Déjeuner")
    diner: str = Field(alias="Dîner")

    model_config = {"populate_by_name": True}


class TipItem(BaseModel):
    icon: str
    title: str
    desc: str


class NutritionAnalysisOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    disease_type: str

    
    age: float
    weight: int
    height: int
    pressure: float
    sugar: float

    
    has_diabetes: bool
    has_hta: bool
    has_dysphagie: bool
    has_denutrition: bool
    has_constipation: bool
    has_avc: bool
    has_depression: bool
    has_epilepsie: bool

    
    imc: float
    imc_label: str
    cognitive_score: float
    motor_score: float
    vasc_score: float
    nutrition_score: float

    
    meal_plan: dict[str, str]
    tips: list[dict[str, str]]
    recommended_foods: dict[str, list[dict[str, str]]]
    avoided_foods: list[dict[str, str]]

    notes: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}




class NutritionAnalysisSummaryOut(BaseModel):
    id: uuid.UUID
    disease_type: str
    age: float
    imc: float
    imc_label: str
    nutrition_score: float
    created_at: datetime

    model_config = {"from_attributes": True}




class NutritionNotesUpdate(BaseModel):
    notes: str