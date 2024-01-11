# include `.env` file if exists
ifneq ("$(wildcard .env)","")
	include .env
	export
endif

run.server.local:
	sh ./run-local.sh

run.server.prod:
	python -m gunicorn api.web.wsgi:application \
		--bind 0.0.0.0:80 \
		--workers ${WORKERS} \
		--threads ${THREADS} \
		--timeout 480

run.celery.local:
	OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES celery -A tasks.app worker --loglevel=DEBUG

run.celery.prod:
	celery -A tasks.app worker --loglevel=INFO

makemigrations:
	python manage.py makemigrations

migrate:
	python manage.py migrate

collectstatic:
	python manage.py collectstatic --no-input

createsuperuser:
	python manage.py createsuperuser --email "" --username admin

# Tests, linters & formatters
fmt:
	make -k ruff-fmt black

lint:
	make -k ruff black-check mypy

black:
	python -m black .

black-check:
	python -m black --check .

ruff:
	python -m ruff .

ruff-fmt:
	python -m ruff --fix-only --unsafe-fixes .

test:
	python -m pytest

mypy:
	python -m mypy .

# Docker
logs:
	docker compose logs -f --tail=100

logs.errors:
	docker compose logs -f --tail=100 | grep -E 'ERROR|WARNING|EXCEPTION|CRITICAL|FATAL|TRACEBACK'

db.dump.all:
	@mkdir -p backups
	$(eval BACKUP_PATH := backups/dump_$(shell date +%Y-%m-%d-%H-%M-%S).sql)
	@docker exec -e PGPASSWORD=${POSTGRES_PASSWORD} ${COMPOSE_PROJECT_NAME}-db-1 pg_dumpall -c -U ${POSTGRES_USER} > ${BACKUP_PATH}
	@echo "Database dumped to '${BACKUP_PATH}'"

db.restore:
	@test -n "$(BACKUP_PATH)" || (echo '`BACKUP_PATH` is not set. Use `make db.restore BACKUP_PATH=<path>`' && exit 1)

	@docker exec -i -e PGPASSWORD=${POSTGRES_PASSWORD} ${COMPOSE_PROJECT_NAME}-db-1 psql -U ${POSTGRES_USER} < ${BACKUP_PATH}
	@echo "Database restored from '${BACKUP_PATH}'"
