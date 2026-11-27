# PayMock Architecture: Payment Authorization Proxy

## Overview

PayMock operates strictly as an in-app **Authorization Proxy**. It intercepts checkout authorization handoffs (such as external wallet app-switches, 3DS authentication challenges, and web redirects) and presents a simulated authorization popover inside the host application.

## Key Design Principles

1. **Separation of Concerns**: PayMock does not calculate carts, taxes, discounts, or capture settlements. It focuses entirely on the authorization state transition (Pending -> Authorized / Cancelled / Declined).
2. **Deterministic CI Automation**: For headless UI and integration tests (XCTest, Maestro), PayMock bypasses presentation and resolves pre-configured outcomes directly.
3. **Accessibility-First UI**: All interactive sheet components carry standard accessibility identifiers for black-box UI test runners.
