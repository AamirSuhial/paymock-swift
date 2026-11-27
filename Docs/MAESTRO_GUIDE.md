# Testing with Maestro

This guide explains how to automate PayMock checkout flows using Maestro.

## Interactive Mode

Maestro can interact directly with the PayMock popover sheet using accessibility identifiers:

- `paymock_sheet`: The popover sheet container
- `paymock_btn_success`: Approve the authorization
- `paymock_btn_cancelled`: Simulate customer cancelling in wallet
- `paymock_btn_insufficient_funds`: Simulate balance decline

### Example Flow

```yaml
appId: com.example.app
---
- launchApp
- tapOn: "Pay with Vipps"
- assertVisible:
    id: "paymock_sheet"
- tapOn:
    id: "paymock_btn_cancelled"
- assertVisible: "Payment was cancelled"
```

## Headless Mode (Fast CI)

Pass launch arguments to resolve outcomes with zero UI:

```yaml
appId: com.example.app
---
- launchApp:
    arguments:
      PAYMOCK_FORCE_VIPPS: "cancelled"
- tapOn: "Pay with Vipps"
- assertVisible: "Payment was cancelled"
```
