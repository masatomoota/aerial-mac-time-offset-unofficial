#!/usr/bin/env python3
import importlib.machinery
import importlib.util
import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
FETCH_PATH = ROOT / "bin" / "aerial-fetch"


def load_fetch_module():
    loader = importlib.machinery.SourceFileLoader("aerial_fetch", str(FETCH_PATH))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


fetch = load_fetch_module()


class FetchTests(unittest.TestCase):
    def test_normalize_list_and_assets_forms(self):
        entries = [{"url-1080-SDR": "https://example.invalid/a.mov"}]
        self.assertEqual(fetch.normalize_entries(entries), entries)
        self.assertEqual(fetch.normalize_entries({"assets": entries}), entries)

    def test_quality_to_key(self):
        self.assertEqual(fetch.quality_to_key("1080-sdr"), "url-1080-SDR")
        self.assertEqual(fetch.quality_to_key("1080-hdr"), "url-1080-HDR")
        self.assertEqual(fetch.quality_to_key("4k-sdr"), "url-4K-SDR")
        self.assertEqual(fetch.quality_to_key("4k-hdr"), "url-4K-HDR")
        self.assertEqual(fetch.quality_to_key("1080-h264"), "url-1080-H264")

    def test_select_variant_and_fallback(self):
        entry = {
            "url-1080-SDR": "https://example.invalid/sdr.mov",
            "url-4K-SDR": "https://example.invalid/4k.mov",
            "url-1080-H264": "https://example.invalid/h264.mov",
        }
        self.assertEqual(fetch.select_variant(entry, "4k-sdr"), ("url-4K-SDR", "https://example.invalid/4k.mov"))
        self.assertEqual(fetch.select_variant(entry, "4k-hdr"), ("url-1080-SDR", "https://example.invalid/sdr.mov"))
        self.assertIsNone(fetch.select_variant({}, "1080-sdr"))

    def test_dry_run_selects_expected_urls_and_limit(self):
        manifest = {
            "assets": [
                {"url-4K-HDR": "https://example.invalid/a.mov"},
                {"url-1080-SDR": "https://example.invalid/b.mov"},
                {"not-a-url": "skip"},
            ]
        }
        self.assertEqual(fetch.dry_run_urls(manifest, "4k-hdr", 0), [
            "https://example.invalid/a.mov",
            "https://example.invalid/b.mov",
        ])
        self.assertEqual(fetch.dry_run_urls(manifest, "4k-hdr", 1), ["https://example.invalid/a.mov"])


if __name__ == "__main__":
    unittest.main()
