from app.db import models


def test_auth_otp_refresh_logout_flow(client, db_session, monkeypatch):
    monkeypatch.setattr("app.services.auth_service.generate_otp", lambda _len: "123456")
    monkeypatch.setattr("app.services.auth_service.send_otp_email_bg", lambda *_args, **_kwargs: None)

    res = client.post("/v1/auth/request-otp", json={"email": "u@example.com"})
    assert res.status_code == 200
    body = res.json()
    assert "cooldownSec" in body

    res = client.post(
        "/v1/auth/verify-otp",
        json={
            "email": "u@example.com",
            "otp": "123456",
            "deviceId": "iphone-1",
            "deviceName": "iPhone",
        },
    )
    assert res.status_code == 200
    payload = res.json()
    assert payload["accessToken"]
    refresh_token = payload["refreshToken"]

    res = client.post("/v1/auth/refresh", json={"refreshToken": refresh_token})
    assert res.status_code == 200
    assert res.json()["accessToken"]

    res = client.post("/v1/auth/logout", json={"refreshToken": refresh_token})
    assert res.status_code == 200

    res = client.post("/v1/auth/refresh", json={"refreshToken": refresh_token})
    assert res.status_code == 401

    user = db_session.query(models.User).filter_by(email="u@example.com").first()
    assert user is not None
