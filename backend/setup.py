from setuptools import find_packages, setup

setup(
    name='solotasks-backend',
    version='0.1.0',
    description='SoloTasks backend API',
    packages=find_packages(include=['app', 'app.*']),
    python_requires='>=3.11',
    install_requires=[
        'fastapi>=0.115.0',
        'uvicorn[standard]>=0.30.0',
        'sqlalchemy>=2.0.31',
        'psycopg[binary]>=3.2.0',
        'alembic>=1.13.2',
        'pydantic>=2.8.2',
        'pydantic-settings>=2.3.4',
        'python-jose[cryptography]>=3.3.0',
        'passlib[bcrypt]>=1.7.4',
        'email-validator>=2.2.0',
        'aiosmtplib>=3.0.1',
        'python-multipart>=0.0.9',
        'boto3>=1.34.147',
        'orjson>=3.10.7',
        'ics>=0.7.2',
    ],
    extras_require={
        'dev': [
            'pytest>=8.3.2',
            'pytest-asyncio>=0.23.8',
            'httpx>=0.27.0',
            'anyio>=4.4.0',
            'ruff>=0.5.5',
        ],
    },
)
