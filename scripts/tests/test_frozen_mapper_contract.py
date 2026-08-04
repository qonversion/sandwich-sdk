import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[2]


class FrozenMapperContractTest(unittest.TestCase):
    def test_frozen_mapper_and_release_fence_require_capable_native_sdks(self) -> None:
        source = (ROOT / "ios" / "sandwich" / "Mappers.swift").read_text()
        podspec = (ROOT / "QonversionSandwich.podspec").read_text()
        gradle = (ROOT / "android" / "sandwich" / "build.gradle").read_text()
        release = (ROOT / "FROZEN_ASSIGNMENT_RELEASE.md").read_text()
        publish = (ROOT / ".github" / "workflows" / "publish_sdks.yml").read_text()

        self.assertNotIn("String(describing: self)", source)
        for case, value in (
            (".auto", '"auto"'),
            (".manual", '"manual"'),
            (".frozen", '"frozen"'),
            (".unknown", '"unknown"'),
        ):
            self.assertIn(f"case {case}:", source)
            self.assertIn(f"return {value}", source)
        self.assertIn("@unknown default:", source)

        self.assertIn('s.dependency "Qonversion", "6.15.0"', podspec)
        self.assertIn("ext.qonversion_version = '9.8.0'", gradle)
        self.assertLess(release.index("Android SDK `9.8.0`"), release.index("Sandwich `7.13.0`"))
        self.assertLess(
            publish.index("python3 scripts/tests/test_frozen_mapper_contract.py"),
            publish.index("pod trunk push"),
        )


if __name__ == "__main__":
    unittest.main()
