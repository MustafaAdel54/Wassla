from routing_engine import load_dataset, Router

DATA = 'data'


def signature(router, origin, destination, departure):
    result = router.route_between_stop_ids(origin, destination, departure)
    assert result is not None
    return (
        result.duration_minutes,
        result.transfers,
        result.walking_minutes,
        [(x.mode, x.route_id, x.from_stop, x.to_stop, x.duration_sec) for x in result.legs],
    )


def test_same_route_independent_of_time():
    router = Router(load_dataset(DATA))
    a = signature(router, 'station_metro_10_AHL_METRO', 'station_metro_23_MAD_METRO', 0)
    for hour in (3, 8, 14, 23):
        assert signature(router, 'station_metro_10_AHL_METRO', 'station_metro_23_MAD_METRO', hour * 3600) == a


def test_surface_to_helwan_independent_of_time():
    router = Router(load_dataset(DATA))
    a = signature(router, 'surface_793', 'surface_807', 0)
    for hour in (3, 12, 23):
        assert signature(router, 'surface_793', 'surface_807', hour * 3600) == a


def test_one_route_only():
    router = Router(load_dataset(DATA))
    result = router.route_between_stop_ids('surface_793', 'surface_556', 3 * 3600)
    payload = router.format_result(result)
    assert payload['found'] is True
    assert 'routes' not in payload
    assert isinstance(payload['segments'], list)
