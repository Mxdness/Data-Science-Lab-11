# ========================
# Variables
# ========================
UV := uv
PYTHON := $(UV) run python
CONFIG := configs/config.toml

RAW := data/raw/Teen_Mental_Health_Dataset.csv
CLEAN := data/processed/clean.csv
FEATURES := data/processed/features.csv

# ========================
# Phony Targets
# ========================
.PHONY: help setup validate clean_data features train classify report pipeline test lint format clean

# ========================
# Help
# ========================
help:
	@echo "Targets:"
	@echo "  make setup        - install dependencies"
	@echo "  make validate     - validate raw + cleaned data"
	@echo "  make clean_data   - preprocess dataset"
	@echo "  make features     - feature engineering"
	@echo "  make train        - train baseline model"
	@echo "  make classify     - compare models"
	@echo "  make report       - generate final report"
	@echo "  make pipeline     - run full pipeline"
	@echo "  make test         - run tests"
	@echo "  make lint         - lint code"
	@echo "  make format       - format code"
	@echo "  make clean        - remove artifacts"

# ========================
# Setup
# ========================
setup:
	$(UV) sync

# ========================
# Validation
# ========================
validate: reports/validation_raw.json reports/validation_cleaned.json

reports/validation_raw.json: $(RAW) src/data/validate.py $(CONFIG)
	$(PYTHON) src/data/validate.py \
		--config $(CONFIG) \
		--input $(RAW) \
		--output reports/validation_raw.json

reports/validation_cleaned.json: $(CLEAN) src/data/validate.py $(CONFIG)
	$(PYTHON) src/data/validate.py \
		--config $(CONFIG) \
		--input $(CLEAN) \
		--output reports/validation_cleaned.json

# ========================
# Cleaning / Preprocessing
# ========================
clean_data: $(CLEAN) reports/cleaning_log.json

$(CLEAN) reports/cleaning_log.json: $(RAW) src/data/preprocess.py $(CONFIG)
	$(PYTHON) src/data/preprocess.py \
		--config $(CONFIG) \

# ========================
# Feature Engineering
# ========================
features: $(FEATURES) reports/feature_log.json

$(FEATURES) reports/feature_log.json: $(CLEAN) src/features/engineer.py $(CONFIG)
	$(PYTHON) src/features/engineer.py \
		--config $(CONFIG) \

# ========================
# Train Baseline
# ========================
train: models/model_v1.pkl reports/metrics.json

models/model_v1.pkl reports/metrics.json: $(FEATURES) src/models/train.py $(CONFIG)
	$(PYTHON) src/models/train.py \
		--config $(CONFIG) \

# ========================
# Classification (Compare Models)
# ========================
classify: models/best_model.pkl reports/classification_metrics.json

models/best_model.pkl reports/classification_metrics.json: $(FEATURES) src/models/benchmark.py $(CONFIG)
	$(PYTHON) src/models/benchmark.py \
		--config $(CONFIG) \

# ========================
# Final Report
# ========================
report: reports/pipeline_report.md

reports/pipeline_report.md: \
	reports/validation_raw.json \
	reports/cleaning_log.json \
	reports/validation_cleaned.json \
	reports/feature_log.json \
	reports/metrics.json \
	reports/classification_metrics.json \
	src/reports/generate_report.py

	$(PYTHON) src/reports/generate_report.py \
		--config $(CONFIG) \
# ========================
# Full Pipeline
# ========================
pipeline: setup clean validate clean_data features train classify report

# ========================
# Testing
# ========================
test:
	$(UV) run pytest

# ========================
# Code Quality
# ========================
lint:
	$(UV) run ruff check .

format:
	$(UV) run ruff format .

# ========================
# Cleanup
# ========================
clean:
	rm -rf data/processed/*
	rm -rf reports/*
	rm -rf models/*.pkl
	rm -rf __pycache__ */__pycache__ */*/__pycache__
	rm -rf .pytest_cache