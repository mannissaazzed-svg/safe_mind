
"""
app/schemas/nutrition_schemas.py
Validation nutrition — patient/nutrition.dart (HealthAnalysis)
"""
 
 
class NutritionAnalysisRequest(BaseModel):
    """
    _calculateMetrics() dans nutrition.dart
    Paramètres saisis par le patient/soignant
    """
    disease_type: str       # 'Alzheimer' | 'Parkinson'
    age: float
    weight: int             # kg
    height: int             # cm
    pressure: float         # mmHg
    sugar: float            # mg/dL
    # Comorbidités
    has_diabetes: bool    = False
    has_hta: bool         = False
    has_dysphagie: bool   = False
    has_denutrition: bool = False
    has_constipation: bool= False
    # Alzheimer only
    has_avc: bool         = False
    has_depression: bool  = False
    has_epilepsie: bool   = False
 
 
class NutritionScores(BaseModel):
    imc: float
    imc_label: str         # 'Normal'|'Dénutrition'|'Surpoids'|'Obésité'
    cognitive_score: float # 0.0 → 1.0
    motor_score: float
    vasc_score: float
    nutrition_score: float
 
 
class MealPlan(BaseModel):
    """Programme repas 4 repas"""
    petit_dejeuner: str
    collation: str
    dejeuner: str
    diner: str
 
 
class NutritionAnalysisResponse(BaseModel):
    scores: NutritionScores
    meal_plan: MealPlan
    tips: list
    healthy_foods: list
    avoid_foods: list
 
 
class NotificationResponse(BaseModel):
    """notifications.dart"""
    id: str
    user_id: str
    title: str
    body: Optional[str] = None
    type: Optional[str] = None
    is_read: bool
    created_at: datetime
 
    class Config:
        from_attributes = True