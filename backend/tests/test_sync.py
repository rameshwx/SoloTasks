def _auth_headers(client, monkeypatch):
    monkeypatch.setattr("app.services.auth_service.generate_otp", lambda _len: "123456")
    monkeypatch.setattr("app.services.auth_service.send_otp_email_bg", lambda *_args, **_kwargs: None)
    client.post("/v1/auth/request-otp", json={"email": "sync@example.com"})
    verify = client.post(
        "/v1/auth/verify-otp",
        json={"email": "sync@example.com", "otp": "123456", "deviceId": "d1", "deviceName": "D1"},
    )
    token = verify.json()["accessToken"]
    return {"Authorization": f"Bearer {token}"}


def test_sync_push_pull_delete(client, monkeypatch):
    headers = _auth_headers(client, monkeypatch)

    task_id = "11111111-1111-1111-1111-111111111111"
    push = {
        "deviceId": "d1",
        "ops": [
            {
                "opId": "op-1",
                "entity": "task",
                "action": "upsert",
                "entityId": task_id,
                "payload": {
                    "title": "Sync task",
                    "status": "todo",
                    "dateLocal": "2026-02-19",
                    "startMin": 600,
                    "endMin": 660,
                },
                "clientTs": "2026-02-19T12:00:00Z",
            },
            {
                "opId": "op-2",
                "entity": "task",
                "action": "delete",
                "entityId": task_id,
                "payload": {},
                "clientTs": "2026-02-19T12:05:00Z",
            },
        ],
    }

    res = client.post("/v1/sync/push", json=push, headers=headers)
    assert res.status_code == 200
    assert res.json()["appliedCount"] == 2

    res = client.get("/v1/sync/pull?cursor=0&deviceId=d1&limit=100", headers=headers)
    assert res.status_code == 200
    changes = res.json()["changes"]
    assert len(changes) >= 2
    assert any(c["action"] == "delete" and c["entity"] == "task" for c in changes)
