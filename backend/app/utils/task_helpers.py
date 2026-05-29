"""
Helpers pour les tâches — style visuel (couleur + image asset).
Miroir exact du map Flutter taskTypes dans CaregiverAddTasks
et getTaskStyle dans SupabaseService.
"""


def get_task_style(task_type: str) -> dict[str, str]:
    styles: dict[str, dict[str, str]] = {
        "medicine": {"color": "indigo",  "image": "assets/medicine.png"},
        "food":     {"color": "orange",  "image": "assets/food.png"},
        "sport":    {"color": "green",   "image": "assets/sport.png"},
        "brain":    {"color": "lime",    "image": "assets/brain.png"},
        "doctor":   {"color": "red",     "image": "assets/doctor.png"},
    }
    return styles.get(task_type, {"color": "indigo", "image": "assets/medicine.png"})
