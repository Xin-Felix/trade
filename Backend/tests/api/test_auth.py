from fastapi.testclient import TestClient


def test_login_email_success(client: TestClient):
    response = client.post(
        "/api/v1/auth/login/email",
        params={"email": "test@example.com", "password": "123456"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["access_token"]
    assert data["user"]["email"] == "test@example.com"


def test_login_email_failure(client: TestClient):
    response = client.post(
        "/api/v1/auth/login/email",
        params={"email": "test@example.com", "password": "wrong"},
    )
    assert response.status_code == 401


def test_register(client: TestClient):
    response = client.post(
        "/api/v1/auth/register",
        params={"email": "new@example.com", "password": "123456"},
    )
    assert response.status_code == 200
    assert response.json()["message"] == "注册成功"

    # 重复注册应失败
    response = client.post(
        "/api/v1/auth/register",
        params={"email": "new@example.com", "password": "123456"},
    )
    assert response.status_code == 400
