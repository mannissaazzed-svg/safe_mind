import uuid

def generate_short_code(user_id: uuid.UUID) -> str:
    return str(user_id).replace("-", "")[:8].upper()