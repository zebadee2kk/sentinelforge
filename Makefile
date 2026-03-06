.PHONY: help setup dev build test lint clean

help:
	@echo "SentinelForge - Make targets"
	@echo ""
	@echo "  setup       - Install dependencies and initialize environment"
	@echo "  dev         - Start development environment"
	@echo "  build       - Build all Docker images"
	@echo "  test        - Run test suite"
	@echo "  lint        - Run code quality checks"
	@echo "  db-init     - Initialize database schema"
	@echo "  db-migrate  - Run database migrations"
	@echo "  clean       - Remove temporary files and containers"
	@echo "  logs        - Tail logs from all services"
	@echo ""

setup:
	@echo "Setting up SentinelForge..."
	python -m venv venv
	./venv/bin/pip install -U pip setuptools wheel
	./venv/bin/pip install -r services/api/requirements.txt
	./venv/bin/pip install -r services/orchestrator/requirements.txt
	@echo "Setup complete. Activate with: source venv/bin/activate"

dev:
	docker-compose -f infra/docker-compose.yml up

build:
	docker-compose -f infra/docker-compose.yml build

test:
	@echo "Running tests..."
	pytest services/api/tests/ -v
	pytest services/orchestrator/tests/ -v
	pytest services/tool-gateway/tests/ -v

lint:
	@echo "Running linters..."
	ruff check services/
	black --check services/
	mypy services/

db-init:
	@echo "Initializing database..."
	docker-compose -f infra/docker-compose.yml exec postgres psql -U sentinelforge -c "CREATE DATABASE sentinelforge;"
	./venv/bin/alembic upgrade head

db-migrate:
	@echo "Running migrations..."
	./venv/bin/alembic upgrade head

clean:
	@echo "Cleaning up..."
	docker-compose -f infra/docker-compose.yml down -v
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name '*.pyc' -delete
	rm -rf .pytest_cache .coverage htmlcov

logs:
	docker-compose -f infra/docker-compose.yml logs -f
