def _auth_headers(client, monkeypatch):
    monkeypatch.setattr("app.services.auth_service.generate_otp", lambda _len: "123456")
    monkeypatch.setattr("app.services.auth_service.send_otp_email_bg", lambda *_args, **_kwargs: None)
    client.post("/v1/auth/request-otp", json={"email": "tags@example.com"})
    verify = client.post(
        "/v1/auth/verify-otp",
        json={"email": "tags@example.com", "otp": "123456", "deviceId": "d1", "deviceName": "D1"},
    )
    token = verify.json()["accessToken"]
    return {"Authorization": f"Bearer {token}"}


def test_task_tag_mapping_endpoints(client, monkeypatch):
    headers = _auth_headers(client, monkeypatch)

    task = client.post(
        "/v1/tasks",
        json={
            "title": "Task with tags",
            "description": "desc",
            "status": "todo",
            "dateLocal": "2026-02-19",
            "startMin": 540,
            "endMin": 600,
        },
        headers=headers,
    ).json()

    tag_a = client.post("/v1/tags", json={"name": "Work"}, headers=headers).json()
    tag_b = client.post("/v1/tags", json={"name": "Urgent"}, headers=headers).json()

    res = client.post(
        f"/v1/tasks/{task['id']}/tags/{tag_a['id']}",
        headers=headers,
    )
    assert res.status_code == 200
    assert [x["name"] for x in res.json()] == ["Work"]

    res = client.put(
        f"/v1/tasks/{task['id']}/tags",
        json={"tagIds": [tag_a["id"], tag_b["id"]]},
        headers=headers,
    )
    assert res.status_code == 200
    assert sorted([x["name"] for x in res.json()]) == ["Urgent", "Work"]

    res = client.get(f"/v1/tasks/{task['id']}/tags", headers=headers)
    assert res.status_code == 200
    assert sorted([x["name"] for x in res.json()]) == ["Urgent", "Work"]

    res = client.delete(
        f"/v1/tasks/{task['id']}/tags/{tag_a['id']}",
        headers=headers,
    )
    assert res.status_code == 200
    assert [x["name"] for x in res.json()] == ["Urgent"]

    res = client.put(
        f"/v1/tasks/{task['id']}/tags",
        json={"tagIds": []},
        headers=headers,
    )
    assert res.status_code == 200
    assert res.json() == []
