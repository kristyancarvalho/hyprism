import importlib.util
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("hyprism_monitoring", ROOT / "scripts/system/monitoring-daemon.py")
MONITORING = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MONITORING)


class MonitoringTests(unittest.TestCase):
    def test_known_sensor_sources_are_normalized(self):
        cases = {
            ("k10temp", "Tctl"): ("cpu", "CPU"),
            ("amdgpu", "edge"): ("gpu", "GPU"),
            ("iwlwifi_1", "iwlwifi_1"): ("wifi", "Wi-Fi"),
            ("nvme", "Composite"): ("nvme", "NVMe"),
            ("acpitz", "acpitz"): ("system", "System"),
        }
        for source, expected in cases.items():
            self.assertEqual(MONITORING.sensor_identity(*source), expected)

    def test_unknown_sensor_preserves_its_label(self):
        self.assertEqual(MONITORING.sensor_identity("custom-hwmon", "Board Zone"), ("generic", "Board Zone"))

    def test_sensor_thresholds_follow_device_category(self):
        self.assertEqual(MONITORING.sensor_thresholds("cpu"), (65, 80, 95))
        self.assertEqual(MONITORING.sensor_thresholds("nvme"), (58, 72, 85))
        self.assertEqual(MONITORING.sensor_thresholds("wifi"), (55, 70, 85))
        self.assertEqual(MONITORING.sensor_thresholds("generic"), (60, 75, 90))

    def test_service_scope_preserves_explicit_unit_type(self):
        item = MONITORING.service_scope({"unit": "backup.timer", "scope": "user"})
        self.assertEqual(item["unit"], "backup.timer")
        self.assertEqual(item["scope"], "user")

    def test_explicit_empty_services_remain_unavailable(self):
        self.assertEqual(MONITORING.services({"services": {"items": []}}), {
            "available": False,
            "healthy": False,
            "items": [],
        })

    def test_service_states_distinguish_active_inactive_failed_and_missing(self):
        item = {"name": "Demo", "unit": "demo.service", "scope": "system"}
        cases = {
            "loaded\nactive\n": "running",
            "loaded\ninactive\n": "inactive",
            "loaded\nfailed\n": "failed",
            "not-found\ninactive\n": "not-found",
        }
        for output, expected in cases.items():
            completed = SimpleNamespace(stdout=output)
            with mock.patch.object(MONITORING.subprocess, "run", return_value=completed):
                self.assertEqual(MONITORING.service_state(item)["state"], expected)
