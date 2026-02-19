def _auth_headers(client, monkeypatch):
    monkeypatch.setattr("app.services.auth_service.generate_otp", lambda _len: "123456")
    monkeypatch.setattr("app.services.auth_service.send_otp_email_bg", lambda *_args, **_kwargs: None)
    client.post("/v1/auth/request-otp", json={"email": "h@example.com"})
    verify = client.post(
        "/v1/auth/verify-otp",
        json={"email": "h@example.com", "otp": "123456", "deviceId": "d1", "deviceName": "D1"},
    )
    token = verify.json()["accessToken"]
    return {"Authorization": f"Bearer {token}"}


def test_holiday_lww_sync_merge(client, monkeypatch):
    headers = _auth_headers(client, monkeypatch)
    holiday_id = "22222222-2222-2222-2222-222222222222"

    res = client.post(
        "/v1/sync/push",
        json={
            "deviceId": "d1",
            "ops": [
                {
                    "opId": "h1",
                    "entity": "holiday",
                    "action": "upsert",
                    "entityId": holiday_id,
                    "payload": {"dateLocal": "2026-04-14", "type": "public", "label": "Old"},
                    "clientTs": "2026-02-19T10:00:00Z",
                },
                {
                    "opId": "h2",
                    "entity": "holiday",
                    "action": "upsert",
                    "entityId": holiday_id,
                    "payload": {"dateLocal": "2026-04-14", "type": "public", "label": "New"},
                    "clientTs": "2026-02-19T10:10:00Z",
                },
            ],
        },
        headers=headers,
    )
    assert res.status_code == 200

    res = client.get("/v1/holidays?year=2026&type=public", headers=headers)
    assert res.status_code == 200
    rows = res.json()
    assert len(rows) == 1
    assert rows[0]["label"] == "New"
