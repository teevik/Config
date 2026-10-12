"""XM6 protocol regression fixtures; pass the packaged sony_ctl.py path."""

import importlib.util
import sys
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("sony_ctl", sys.argv.pop(1))
sony = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sony)


class Xm6Tests(unittest.TestCase):
    def test_xm6_write_layout(self):
        # XM6 captures: https://github.com/sevsev9/sonyctl/blob/main/docs/MDR_PROBE_RESULTS.md
        for mode, enabled, ambient in [("off", 0, 0), ("anc", 1, 0), ("transparency", 1, 1)]:
            with self.subTest(mode=mode):
                self.assertEqual(
                    sony._nc_payload(mode, 12, 0x19),
                    bytes([0x68, 0x19, 1, enabled, ambient, 0, 12, 0, 0]),
                )

    def test_xm6_queries_real_state_instead_of_dummy_xm5_reply(self):
        requests = []

        class Session:
            def __init__(self, *args):
                pass

            def open(self):
                return True

            def close(self):
                pass

            def transact(self, payload, **kwargs):
                requests.append(payload)
                if payload == sony.P_NC_GET:
                    return [(0x0C, bytes.fromhex("67 17 00 00 00 00 00"))]
                if payload == sony.P_NC_GET_ALT:
                    return [(0x0C, bytes.fromhex("67 19 01 01 01 01 0c 01 00"))]
                return []

        with (
            patch.object(sony, "SonySession", Session),
            patch.object(sony, "resolve_channel", return_value=9),
            patch.object(sony, "_load_cache", return_value={}),
            patch.object(sony, "_save_cache"),
            patch.object(sony, "bluez_battery", return_value=66),
        ):
            state = sony.query_device("00:11:22:33:44:55", "WH-1000XM6")

        self.assertIn(sony.P_NC_GET_ALT, requests)
        self.assertNotIn(sony.P_NC_GET, requests)
        self.assertEqual(state["noise_mode"], "transparency")
        self.assertEqual(state["nc_subtype"], 0x19)
        self.assertEqual(state["ambient_level"], 12)
        self.assertTrue(state["focus_voice"])
        self.assertTrue(state["auto_ambient"])

    def test_xm5_write_layout_is_preserved(self):
        self.assertEqual(
            sony._nc_payload("transparency", 12, 0x17),
            bytes.fromhex("68 17 01 01 01 02 00 0c"),
        )


if __name__ == "__main__":
    unittest.main()
