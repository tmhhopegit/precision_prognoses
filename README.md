# High-confidence prediction

**Question:** for which patients can we say, with at least a chosen precision (e.g. 90%), that they *will* or *will not* be impaired on a task, and how many patients is that?

For each target precision, the method picks score cut-offs on the training patients and then predicts new patients who pass them. Everything is evaluated by nested cross-validation, so the reported precision is what the method achieves on patients it hasn't seen.

## Layout

| Path | Contents |
|---|---|
| `analysis/` | This project's own code. |
| `shared/` | Helpers (data loading, folds, thresholds, precision). 
| `tests/` | `matlab.unittest` tests. |
| `config_*.m`, `setup_*.m`, `example_*.m` | Settings, path setup and a worked example. |

## Setting up

1. In MATLAB, run `setup_confidence` from this folder, or `run('<path to this folder>/setup_confidence.m')` from anywhere. It puts this project's `analysis`, `shared` and `tests` folders on the path.
2. Copy the settings with `cfg = config_confidence();` and change what you need. Every setting is documented in `config_confidence.m`.
3. Work through `example_confidence.m` section by section.

Check it works by running `runtests('tests')` from this folder. Tests that need the Statistics and Machine Learning Toolbox are skipped if it isn't installed.

The main entry point is `results = run_confidence_analysis(P, cfg)`. It saves `confidence_<task>.mat` files and `confidence_summary.csv` in `cfg.results_dir`, with one table row per target precision:

- `PPV`, `NPV`: precision, pooled over repeats.
- `PPV_n`, `NPV_n`: how many patients are predicted per repeat.
- `PPV_found`, `NPV_found`: the share of each class found.

Tables are produced for all patients, the early subgroup and, if configured, the initially impaired.

- **Parallel runs:** set `cfg.workers` to the number of workers. Use 0 to run serially without the Parallel Computing Toolbox.

## Data

`load_ploras(cfg)` reads the PLORAS spreadsheet, the impairment thresholds and the lesion images (it needs SPM), using the paths in `cfg.data`. It replaces the `PLORAS_parallel` constructor.

A saved `PLORAS_parallel` object works anywhere a data struct `P` is expected: thresholds are looked up by score name, and predictor names are inferred.


