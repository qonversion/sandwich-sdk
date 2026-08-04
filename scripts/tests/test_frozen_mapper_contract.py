import pathlib
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[2]


class FrozenMapperContractTest(unittest.TestCase):
    def test_objc_enum_is_mapped_by_cases_not_description(self) -> None:
        source = (ROOT / "ios" / "sandwich" / "Mappers.swift").read_text()
        self.assertNotIn("String(describing: self)", source)
        for case, value in (
            (".auto", '"auto"'),
            (".manual", '"manual"'),
            (".frozen", '"frozen"'),
            (".unknown", '"unknown"'),
        ):
            self.assertIn(f"case {case}:", source)
            self.assertIn(f"return {value}", source)


if __name__ == "__main__":
    unittest.main()
