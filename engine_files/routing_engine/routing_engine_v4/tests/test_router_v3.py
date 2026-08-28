from routing_engine import load_dataset, Router
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / 'data'


def test_single_route_api():
    ds = load_dataset(ROOT)
    r = Router(ds)
    result = r.route_between_stop_ids(
        'station_metro_14_HOF_METRO',
        'station_metro_23_MAD_METRO',
        departure_time_sec=6 * 3600,
    )
    assert result is not None
    assert result.arrival_sec > result.departure_sec
    assert result.legs

    formatted = r.format_result(result)
    assert formatted['found'] is True
    assert len(formatted['segments']) == 1
    assert formatted['segments'][0]['title'] == 'Metro Line 1'
    assert formatted['segments'][0]['from'] == 'Wadi Hof'
    assert formatted['segments'][0]['to'] == 'Maadi'


def test_no_alternatives_api():
    ds = load_dataset(ROOT)
    r = Router(ds)
    result = r.route_between_stop_ids(
        'station_metro_14_HOF_METRO',
        'station_metro_23_MAD_METRO',
        departure_time_sec=6 * 3600,
    )
    assert not isinstance(result, list)
