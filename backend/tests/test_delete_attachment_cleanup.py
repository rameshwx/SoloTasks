def _auth_headers(client, monkeypatch):
    monkeypatch.setattr("app.services.auth_service.generate_otp", lambda _len: "123456")
    monkeypatch.setattr("app.services.auth_service.send_otp_email_bg", lambda *_args, **_kwargs: None)
    client.post("/v1/auth/request-otp", json={"email": "del@example.com"})
    verify = client.post(
        "/v1/auth/verify-otp",
        json={"email": "del@example.com", "otp": "123456", "deviceId": "d1", "deviceName": "D1"},
    )
    token = verify.json()["accessToken"]
    return {"Authorization": f"Bearer {token}"}


def test_delete_task_marks_attachments_deleted(client, db_session, monkeypatch):
    headers = _auth_headers(client, monkeypatch)

    task = client.post(
        "/v1/tasks",
        json={
            "title": "Task",
            "description": "desc",
            "status": "todo",
            "dateLocal": "2026-02-19",
            "startMin": 500,
            "endMin": 560,
        },
        headers=headers,
    ).json()

    res = client.post(
        f"/v1/tasks/{task['id']}/attachments",
        json={
            "type": "pdf",
            "name": "a.pdf",
            "size": 100,
            "remoteKey": "users/x/a.pdf",
            "cachedPath": None,
            "keepOffline": False,
        },
        headers=headers,
    )
    assert res.status_code == 201

    res = client.delete(f"/v1/tasks/{task['id']}", headers=headers)
    assert res.status_code == 200

    list_res = client.get(f"/v1/tasks/{task['id']}/attachments", headers=headers)
    assert list_res.status_code == 200
    assert list_res.json() == []
