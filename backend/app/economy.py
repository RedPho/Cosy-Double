def calculate_passive_leaves(duration_seconds: int) -> int:
    """
    Passive Income: 1 Leaf per 5 minutes (300 seconds), 
    bounded by the Anti-Farming Cap (max 30 Leaves per session / 2.5 hours / 150 minutes).
    """
    duration_minutes = duration_seconds // 60
    passive_earned = duration_minutes // 5
    # Cap passive earnings at 30 Leaves
    return min(passive_earned, 30)

def calculate_active_leaves(completed_tasks_count: int) -> int:
    """
    Active Income: 2 Leaves per task marked [DONE].
    """
    return completed_tasks_count * 2

def calculate_session_earnings(duration_seconds: int, completed_tasks_count: int) -> tuple[int, int, int]:
    """
    Calculate the total session earnings.
    Returns: (total_leaves, passive_leaves, active_leaves)
    """
    passive = calculate_passive_leaves(duration_seconds)
    active = calculate_active_leaves(completed_tasks_count)
    return (passive + active, passive, active)
