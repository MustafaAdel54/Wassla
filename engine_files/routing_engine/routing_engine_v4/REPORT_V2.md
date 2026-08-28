# V2 verification report

Environment: Python 3.13
Tests: 2 passed

Verified:
- Metro Line 1 routing from Helwan station to Maadi station.
- Station-level lookup works without requiring a platform-specific stop ID.
- Consecutive Line 1 connections are returned as one logical transit leg.
- Alternative route results are deduplicated by transit path signature.

Observed prototype result for 06:00:
Helwan station -> Maadi station: ~24 minutes, 0 transfers.

This number is for graph/schedule verification only and is not a production ETA.
