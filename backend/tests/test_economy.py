import pytest
from backend.app.economy import (
    calculate_passive_leaves, 
    calculate_active_leaves, 
    calculate_session_earnings
)

def test_passive_leaves_calculation():
    # 0 seconds -> 0 leaves
    assert calculate_passive_leaves(0) == 0
    
    # 4 minutes (240 seconds) -> 0 leaves (need 5 minutes)
    assert calculate_passive_leaves(240) == 0
    
    # 5 minutes (300 seconds) -> 1 leaf
    assert calculate_passive_leaves(300) == 1
    
    # 12 minutes (720 seconds) -> 2 leaves
    assert calculate_passive_leaves(720) == 2
    
    # 2.5 hours (150 minutes / 9000 seconds) -> 30 leaves
    assert calculate_passive_leaves(9000) == 30
    
    # 3 hours (180 minutes / 10800 seconds) -> capped at 30 leaves (Anti-Farming Cap)
    assert calculate_passive_leaves(10800) == 30
    
    # 24 hours -> capped at 30 leaves
    assert calculate_passive_leaves(86400) == 30

def test_active_leaves_calculation():
    assert calculate_active_leaves(0) == 0
    assert calculate_active_leaves(1) == 2
    assert calculate_active_leaves(5) == 10

def test_session_earnings_combination():
    # 15 minutes connection (3 leaves) + 2 tasks completed (4 leaves) -> 7 leaves total
    total, passive, active = calculate_session_earnings(15 * 60, 2)
    assert total == 7
    assert passive == 3
    assert active == 4

    # 4 hours connection (capped 30 leaves) + 5 tasks completed (10 leaves) -> 40 leaves total
    total, passive, active = calculate_session_earnings(240 * 60, 5)
    assert total == 40
    assert passive == 30
    assert active == 10
