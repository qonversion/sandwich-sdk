#!/usr/bin/env swift

/// Tests for handleEntitlementsResult fix (SUP3-30)
///
/// Validates that entitlements are prioritized over errors when both
/// are present. This fixes the case where Stripe users on iOS lose
/// their entitlements because the SDK discards them when StoreKit
/// returns SKError.paymentInvalid due to empty Apple receipt.

import Foundation

// MARK: - Test Harness

var passed = 0
var failed = 0

func assertEqual<T: Equatable>(_ a: T, _ b: T, _ msg: String, file: String = #file, line: Int = #line) {
  if a == b { passed += 1 } else { failed += 1; print("  FAIL (\(line)): \(msg) - got \(a), expected \(b)") }
}
func assertNil<T>(_ value: T?, _ msg: String, line: Int = #line) {
  if value == nil { passed += 1 } else { failed += 1; print("  FAIL (\(line)): \(msg) - expected nil, got \(value!)") }
}
func assertNotNil<T>(_ value: T?, _ msg: String, line: Int = #line) {
  if value != nil { passed += 1 } else { failed += 1; print("  FAIL (\(line)): \(msg) - expected non-nil") }
}

// MARK: - Simulate handleEntitlementsResult

/// Original (buggy) implementation: error takes priority
func handleEntitlementsResult_original(
  _ entitlements: [String: [String: Any]],
  _ error: NSError?,
  completion: (_ result: [String: Any]?, _ error: NSError?) -> Void
) {
  if let error = error {
    return completion(nil, error)
  }
  completion(entitlements, nil)
}

/// Fixed implementation: entitlements take priority over error
func handleEntitlementsResult_fixed(
  _ entitlements: [String: [String: Any]],
  _ error: NSError?,
  completion: (_ result: [String: Any]?, _ error: NSError?) -> Void
) {
  if !entitlements.isEmpty {
    completion(entitlements, nil)
    return
  }

  if let error = error {
    return completion(nil, error)
  }

  completion([:], nil)
}

// MARK: - Test Data

let stripeEntitlements: [String: [String: Any]] = [
  "jumpspeak_premium": [
    "id": "jumpspeak_premium",
    "active": true,
    "source": "stripe",
    "expiration_timestamp": 1798135224
  ]
]

let skError = NSError(
  domain: "SKErrorDomain",
  code: 4,
  userInfo: [NSLocalizedDescriptionKey: "The operation couldn't be completed. (SKErrorDomain error 4.)"]
)

// MARK: - Tests

print("Running handleEntitlementsResult tests...\n")

// Test 1: Original behavior discards entitlements when error present
print("1. Original behavior: error discards entitlements")
handleEntitlementsResult_original(stripeEntitlements, skError) { result, error in
  assertNil(result, "original: entitlements should be nil when error present")
  assertNotNil(error, "original: error should be returned")
  assertEqual(error?.code ?? 0, 4, "original: error code should be 4 (PaymentInvalid)")
}

// Test 2: Fixed behavior preserves entitlements when both present
print("2. Fixed behavior: entitlements preserved over error")
handleEntitlementsResult_fixed(stripeEntitlements, skError) { result, error in
  assertNotNil(result, "fixed: entitlements should be returned")
  assertNil(error, "fixed: error should be nil when entitlements exist")
  let premium = result?["jumpspeak_premium"] as? [String: Any]
  assertNotNil(premium, "fixed: jumpspeak_premium key should exist")
  assertEqual(premium?["source"] as? String ?? "", "stripe", "fixed: source should be stripe")
}

// Test 3: Fixed behavior returns error when entitlements empty
print("3. Fixed behavior: error returned when entitlements empty")
handleEntitlementsResult_fixed([:], skError) { result, error in
  assertNil(result, "empty entitlements: result should be nil")
  assertNotNil(error, "empty entitlements: error should be returned")
  assertEqual(error?.code ?? 0, 4, "empty entitlements: error code should be 4")
}

// Test 4: Normal case - entitlements without error
print("4. Normal case: entitlements without error")
handleEntitlementsResult_fixed(stripeEntitlements, nil) { result, error in
  assertNotNil(result, "normal: entitlements should be returned")
  assertNil(error, "normal: no error")
}

// Test 5: No entitlements, no error
print("5. Edge case: no entitlements, no error")
handleEntitlementsResult_fixed([:], nil) { result, error in
  assertNotNil(result, "empty: should return empty dict, not nil")
  assertNil(error, "empty: no error")
}

// Test 6: Multiple entitlements with error - all preserved
print("6. Multiple entitlements with error - all preserved")
let multiEntitlements: [String: [String: Any]] = [
  "premium": ["id": "premium", "active": true, "source": "stripe"],
  "pro": ["id": "pro", "active": true, "source": "stripe"]
]
handleEntitlementsResult_fixed(multiEntitlements, skError) { result, error in
  assertNotNil(result, "multi: entitlements should be returned")
  assertNil(error, "multi: error should be nil")
  assertEqual(result?.count ?? 0, 2, "multi: both entitlements should be present")
}

// MARK: - Summary

print("\nResults: \(passed) passed, \(failed) failed, \(passed + failed) total")
if failed > 0 {
  print("TESTS FAILED")
  exit(1)
} else {
  print("ALL TESTS PASSED")
}
