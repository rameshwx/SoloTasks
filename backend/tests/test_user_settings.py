def _auth_headers(client, monkeypatch):
    monkeypatch.setattr("app.services.auth_service.generate_otp", lambda _len: "123456")
    monkeypatch.setattr("app.services.auth_service.send_otp_email_bg", lambda *_args, **_kwargs: None)
    client.post("/v1/auth/request-otp", json={"email": "prefs@example.com"})
    verify = client.post(
        "/v1/auth/verify-otp",
        json={"email": "prefs@example.com", "otp": "123456", "deviceId": "d1", "deviceName": "D1"},
    )
    token = verify.json()["accessToken"]
    return {"Authorization": f"Bearer {token}"}


def test_user_settings_preferences_roundtrip(client, monkeypatch):
    headers = _auth_headers(client, monkeypatch)

    initial = client.get("/v1/settings/preferences", headers=headers)
    assert initial.status_code == 200
    body = initial.json()
    assert "reminderDefaults" in body
    assert "calendarPrefs" in body
    assert "holidayPrefs" in body
    assert "updatedAt" in body

    payload = {
        "reminderDefaults": {
            "defaultRelativeMin": 30,
            "quickOptions": [10, 30, 60],
            "autoCreate": False,
        },
        "calendarPrefs": {
            "weekStart": "monday",
            "timeFormat": "24h",
        },
        "holidayPrefs": {
            "warnWhenSchedulingOnHoliday": True,
            "hideTasksOnHolidays": True,
        },
    }
    saved = client.put("/v1/settings/preferences", json=payload, headers=headers)
    assert saved.status_code == 200
    assert saved.json()["calendarPrefs"]["weekStart"] == "monday"
    assert saved.json()["calendarPrefs"]["timeFormat"] == "24h"
    assert saved.json()["holidayPrefs"]["hideTasksOnHolidays"] is True

    fetched = client.get("/v1/settings/preferences", headers=headers)
    assert fetched.status_code == 200
    assert fetched.json()["reminderDefaults"]["defaultRelativeMin"] == 30
    assert fetched.json()["calendarPrefs"]["weekStart"] == "monday"
    assert fetched.json()["holidayPrefs"]["hideTasksOnHolidays"] is True


def test_user_settings_validation_422(client, monkeypatch):
    headers = _auth_headers(client, monkeypatch)
    payload = {
        "reminderDefaults": {
            "defaultRelativeMin": 15,
            "quickOptions": [5, 15],
            "autoCreate": False,
        },
        "calendarPrefs": {
            "weekStart": "monday",
            "timeFormat": "bad-value",
        },
        "holidayPrefs": {
            "warnWhenSchedulingOnHoliday": True,
            "hideTasksOnHolidays": False,
        },
    }
    res = client.put("/v1/settings/preferences", json=payload, headers=headers)
    assert res.status_code == 422

